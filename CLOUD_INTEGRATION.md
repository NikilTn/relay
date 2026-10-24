# Native cloud integration — build 8

Build 8 adds a native cloud client and request conversations. The tested AWS API
runs on this Mac at `http://127.0.0.1:8788`. **No hosted HTTPS API exists yet.**
Phones require an HTTPS endpoint; the production app refuses HTTP endpoints and
never sends AWS credentials. See cloud/docs/CLOUD_DEPLOYMENT_HANDOFF.md for the
organizer role/PassRole blocker. A localhost URL on an iPhone addresses the iPhone.

## Implemented

- Cloud tab: Cognito authorization code + PKCE/state validation with
  ASWebAuthenticationSession, Keychain token storage/refresh, server-authoritative
  profile, authorized shelter directory and explicit local-to-cloud shelter links.
- Help review: optional **Also queue for cloud** when signed in and the destination
  is linked. The immutable request and cloud outbox intent commit in one SQLite
  transaction. Existing local requests can be explicitly queued from their detail.
- Outbox scopes include API URL and account subject. Persisted IDs/content survive
  retries and restart; timeout never implies acceptance. Cloud acceptance, analysis,
  destination receipt and human progress remain separate. Cached account/directory
  data allow previously configured requests to queue while offline. Reauthorization
  and membership changes are still enforced by the backend when reconnecting.
- Cloud inbox: own requests or a dispatcher-authorized shelter inbox, validated
  Bedrock proposal and review reasons, request conversation, reported progress and
  cancellation. Commands retain operation IDs; revision conflicts require refresh.
- Backend `/v1/me`, request `/history` and `/events`. Server checks ownership,
  shelter membership, role, status transitions, revision and duplicate commands.
  Histories are bounded to 100 events. "Completed" is a human report, not an
  inventory reservation or independently verified resource delivery.
- Nearby request threads: replies/progress use durable addressed envelopes through
  the existing relay. They stay out of personal chats. These are explicitly
  device-reported/unverified updates, separate from authenticated cloud history.
- Voice: user-triggered microphone permission, mono PCM16 WAV at 16 kHz (maximum
  60 seconds), private upload, resumable transcription IDs, editable transcript and
  explicit **Use reviewed text in Help**. Recording never submits a request.
  Recording/job reference stays on device for retry. Returned S3 grants never
  receive the API bearer token. Raw audio is not forwarded by the P2P text engine.
- Clear Done controls for new text fields, readable cloud errors, request IDs and
  retry state. The existing messages, shelters, drafts and receipts are retained.

## Configuration after hosting

1. Organizer provisions the dedicated role and scoped PassRole from
   cloud/docs/ORGANIZER_REQUEST.md. Deploy the tested integration commit, not the
   older backend PR snapshot. Current API/worker packaging and deployment files are
   in cloud/infra and cloud/scripts. Validate actual HTTPS/auth/worker behavior.
2. Set `RELAY_CLOUD_API_URL=https://...` while generating the Xcode project, then
   archive a new unused build number. For engineering testing, enter that URL in
   Cloud on an existing build. URLs containing credentials/query/fragment or HTTP
   are refused. Existing installed configuration overrides the bundled default.
3. Sign in with an enrolled Cognito account, including its MFA challenge. The
   workshop AWS console login and Apple/TestFlight account are not this app login.
   Self sign-up is disabled; no shared password/token is embedded in the app.
4. Cloud → link a saved local shelter to an authorized cloud inbox. The local
   shelter's device address and existing messages remain unchanged.
5. Help → Review → enable Also queue for cloud → Save. Requests → request shows
   nearby delivery; Cloud → request shows cloud acceptance, AI proposal and replies.
6. Dispatcher sign-in → Cloud → choose authorized shelter → Load shelter requests.
   Reply or move new → accepted → in_progress → completed; requester can cancel
   before a terminal state. Confirm the requester sees the same durable history.
7. Cloud → Record a request → Record/Stop → Transcribe → correct the text → Use
   reviewed text in Help. Finish shelter/quantity/location and explicitly submit.

## Verification and boundaries

43 Swift tests and 35 backend tests pass. The actual Swift URLSession client passed
fixture HTTP and real Cognito/DynamoDB/Bedrock/S3/Transcribe checks on the Mac:
text, lost-response replay, duplicate progress commands, WAV transcription, explicit
corrected-transcript submission and independent DynamoDB readback. See TEST_RESULTS.
This uses the same DTOs/HTTP client as the app but **does not test native browser
PKCE, microphone capture, Keychain refresh, or the complete phone UI flow**.

Native Mac UI checks cover endpoint rejection, local reply composition, progress,
queued state, reusable composer and Done. Both physical iPhones installed/launched
build 8 and retained all previous data. Physical no-router tests remain unverified.

Remaining limits:

- No public HTTPS hosting yet; native account login/refresh, microphone capture,
  real phone cloud recovery, account-switch and sign-out race behavior need device
  verification after hosting. A full hosted failure/recovery test is required.
- Only an origin's own requests upload under its account. **A carrier cannot upload
  somebody else's request under its own login.** Signed origin enrollment/envelopes,
  gateway ingestion and trustworthy cloud results carried back offline are separate
  pending work. Current P2P forwarding itself continues independently.
- No synchronized multi-device shelter membership or automatic online shelter
  enrollment. Directory linking is explicit, scoped to this account/endpoint.
- No inventory reservation, responder assignment/dispatch optimization, or verified
  fulfillment. Cloud/nearby histories are separate; no cross-transport conflict merge.
- New local reply envelopes require build 8 at endpoints for the thread UI; older
  carriers preserve bytes but older endpoints may present them as plain chat.
- P2P remains plaintext/unauthenticated. Sign-in secures cloud API authorization,
  not the existing radio link or local database. Use synthetic data only.
- Foreground encounters, manual Connect and no background/terminated discovery.
  Audio retention cleanup, noisy-speech evaluation, Android and disaster-scale
  reliability remain out of scope for this build.

## Repeatable software check

```sh
xcrun swift test
python3 scripts/tcp_experiment.py
# Use the backend virtualenv; no AWS calls in this test suite.
python -m pytest cloud/tests -q
python cloud/scripts/bootstrap_local.py --runtime-dir /tmp/relay-fixture --port 18788
PYTHONPATH=cloud python -m relay_backend serve --config /tmp/relay-fixture/local-config.json --port 18788
# Separate terminal:
PYTHONPATH=cloud python -m relay_backend worker --config /tmp/relay-fixture/local-config.json
.build/debug/RelayCloudCheck --url http://127.0.0.1:18788 \
  --tokens /tmp/relay-fixture/local-test-tokens.json \
  --requester test-requester-a --dispatcher test-dispatcher-a \
  --db /tmp/relay-swift-check.sqlite --audio cloud/fixtures/synthetic-speech.wav
```

The CLI permits loopback only as an explicit control; production app HTTPS rules
stay intact. Real mode requires `--allow-live` and an already approved bounded test
budget. Every CLI run creates a fresh synthetic request; retries *within* a run
replay the same immutable request. Do not mistake separate runs for outbox retries.
