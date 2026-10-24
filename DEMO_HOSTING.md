# RELAY temporary HTTPS demo

As checked on 2026-10-24, the demo API is:

**https://resumes-investigated-striking-mba.trycloudflare.com**

This is an API, not a dispatcher website. Open RELAY's Cloud tab to use the native
requester/dispatcher interface. Build 9 bundles this URL. If a previous endpoint
was saved, sign out and replace the address before signing in again.

## What runs where

Phone/Mac RELAY → HTTPS Cloudflare tunnel → API process on this Mac → actual AWS
Cognito, S3, Transcribe, Bedrock Nova Lite and DynamoDB. A worker on this Mac
processes durable AWS jobs. Cloudflare carries API traffic; it does not host the
Python process. The existing separate offline Apple peer-to-peer engine continues
to handle addressed text envelopes, storage acknowledgements and final receipts.

Lambda/API Gateway is the preferred permanent target. The required dedicated
execution role is still absent in the workshop account. App Runner would also
require deployment/access setup. A named Cloudflare tunnel can provide a stable
hostname when an account/domain is configured. The current Quick Tunnel has a
temporary hostname and no uptime guarantee; restarting it normally changes the URL.
See [Cloudflare documentation](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/)
and [Lambda execution roles](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html).

## Current owner setup

- API binds only `127.0.0.1:8788`, using AWS mode and Cognito token validation.
- Tunnel forwards only that port. The API does not serve local files or credentials.
- Private login helper binds a different loopback port, `127.0.0.1:8891`, for the
  owner to sign into pre-enrolled synthetic accounts. It expires after two hours.
  Do not expose this helper, copy credentials into source, or share it with judges.
- Original-bundle build 9 is installed and launched on both physical phones, with
  identities, all prior messages/receipts, and shelters preserved.
- The first live backend source was cfcaade434114; build 9 changes the native WAV
  importer and endpoint configuration, not the cloud request/worker logic.
- Existing AWS worker is reused. Do not start another worker while it is running.
- Synthetic test counters last verified: 17/30 requests and 3/5 audio jobs. The
  caps are shared across all clients, not reset on restart. Health/read tests do
  not create requests. These counters are not a dollar-billing statement.

## Test on the prepared devices

1. Keep this Mac powered, awake, lid open and online. The active four-hour
   `caffeinate -i` session began around 00:20 PDT; extend it before judging if needed.
   Keep the API, worker and tunnel processes running. Workshop AWS credentials
   must remain valid. iPhones need internet for this cloud test.
2. Open the original RELAY development app, Cloud → Sign in securely. Use the
   private owner-only helper to sign in as Requester-A on the 15 Pro Max and
   Dispatcher-A on the iPhone 16 or Mac, including the current MFA code. This is a
   Cognito app account, not the AWS console or Apple account. Self-signup is disabled.
3. On requester, link a saved local shelter to the authorized cloud shelter inbox.
   This explicit mapping does not change the local shelter's receiving-device UUID.
4. Help → choose that shelter → synthetic water request → Review → Also queue for
   cloud → Save. Record the immutable UUID. Cloud should first show accepted, then
   a reviewable AI proposal. Neither state means supplies were allocated.
5. On dispatcher, choose the corresponding shelter → Load shelter requests. Open
   that exact UUID, reply and progress through accepted → in progress → reported
   completed. Requester sync should show the same history. This does not decrement
   stock, assign a responder or independently prove delivery.
6. For voice, Cloud → Record a request. Record a short synthetic phrase, or Import
   WAV recording with `cloud/fixtures/synthetic-speech.wav`. Transcribe, correct
   the text, select Use reviewed text in Help, then explicitly review and submit.
   Expect Bedrock to extract the item/amount from the reviewed text. Recording or
   transcription alone must not create a help request.
7. While signed in/configured, remove internet from requester, queue a fresh
   synthetic request, and relaunch the app. Verify the same queued UUID remains.
   Restore internet and sync. Require one cloud request and one logical result.
   Run this only within the shared test caps; record outcomes in TEST_RESULTS.md.
8. Separately run physical tests A–E in TEST_PLAN.md. Cloud is unavailable with
   internet disabled. Leave required local radios enabled and detach ordinary
   Wi-Fi infrastructure. Cloud test success does not prove an offline radio path.

Native login, microphone, WAV import and phone cloud UI are still awaiting operator
verification. Do not present this procedure as a passed test until actual evidence
is recorded.

## Restart and troubleshooting

Check `GET /v1/health` publicly, then a signed-in profile/read. Health alone checks
API liveness, not AWS credentials, worker progress or model health. Expected: no
token/invalid token receives 401 for `/v1/me`.

Run from the integration checkout with a Python environment containing
`cloud/requirements.txt`. Use the existing private AWS configuration; never use
fixture/local-test authentication on a public tunnel:

```sh
PYTHONPATH=cloud /path/to/venv/bin/python -m relay_backend serve \
  --config /private/runtime/aws-config-tunnel.private.json --port 8788
# Only if the existing worker is stopped:
PYTHONPATH=cloud /path/to/venv/bin/python -m relay_backend worker \
  --config /private/runtime/aws-config-tunnel.private.json
# Only if the existing tunnel is stopped (this normally creates a new hostname):
cloudflared tunnel --url http://127.0.0.1:8788 --no-autoupdate
caffeinate -i -t 14400
```

For a new hostname, update a private config copy's `public_base_url`, restart the
API with that copy, and update the app's Cloud address. Saved cloud queues are
scoped by endpoint/account; do not assume an old-endpoint outbox is automatically
migrated. Keep the current tunnel running through the demonstration.

The private owner helper can be restarted separately:

```sh
python3 cloud/scripts/demo_login_panel.py \
  --identities /private/runtime/demo-identities.private.json
```

When done, stop the tunnel first, then only this demo API/helper/keep-awake
processes. Coordinate before stopping the shared worker. Local app stores and
AWS records persist; this procedure does not delete them.

## Honest presentation

“Our prototype API and worker run on this Mac behind HTTPS. Speech recognition,
language-model interpretation and durable cloud storage use real AWS services.
The Apple devices also have a separate store-and-forward text transport.”

No inventory transaction, autonomous dispatch, authenticated carrier-to-cloud
gateway, offline speech recognition, Android transport or production disaster
resilience is claimed. A carried request cannot currently be uploaded under the
carrier's account, and cloud replies are not yet securely relayed back offline.
