# Backend test results — 2026-10-24 UTC

**The backend is implemented and locally verified. The full real-cloud milestone is not yet verified.** Live AWS auth/data/model/audio tests await the explicit spending/resource approval required by the handoff. Public hosting additionally awaits a dedicated organizer execution role and separate approval.

| Area | Status | Evidence / limitation |
|---|---|---|
| Local automated tests | PASS | 27 pytest cases; no AWS calls; 2.57 seconds |
| Independent HTTP client | PASS | Real loopback API + separate worker, fixture providers; 2026-10-24 05:01:42–05:01:50 UTC |
| Process restart / lost-response replay | PASS | Real API process stopped/restarted before worker start; one logical record, one analysis |
| Durable local storage | PASS | SQLite committed before acceptance, reopened across processes, pending work recovered |
| Durable DynamoDB write path | NOT TESTED | SDK adapter wire-contract tests pass; metadata and reserved namespace reads pass; no live writes |
| Local authentication / isolation | PASS | Signed fixture JWTs; expiry/issuer/client/token-use/enrollment; owner/shelter/role isolation |
| AWS operator authentication | PASS | Official AWS CLI browser login and STS verified expected workshop account |
| Real Cognito user authentication | NOT TESTED | Pool/client/MFA metadata only; new client/test accounts not provisioned |
| Native PKCE login | NOT TESTED | Flow/config documented, no Apple app changes |
| Real Bedrock inference | NOT TESTED | Nova Lite availability AUTHORIZED/AVAILABLE, not a runtime invocation |
| Real Amazon Transcribe | NOT TESTED | No jobs started; fixture transcript is fixed synthetic text |
| API reachability on this Mac | PASS | `http://127.0.0.1:8787`, fixture mode |
| Public/iPhone API reachability | NOT TESTED | No HTTPS deployment/public tunnel; loopback cannot serve a separate iPhone |
| Lambda artifact / template | PASS (build/syntax only) | Linux arm64 ZIP built; AWS ValidateTemplate succeeded |
| Lambda runtime / deployed permissions | NOT TESTED | Dedicated execution role absent; no deployment |
| Native app / offline gateway integration | NOT TESTED | No Swift, transport, signing, Xcode or physical-phone changes |

## Automated coverage

The 27 passing cases cover signed-token boundaries, durable acceptance, identical replay/content conflict, owner/shelter permissions, requester-versus-dispatcher separation, owner-bound pagination, missing quantity/negation/contradictory shelter/negative or multiple quantities, compound quantities, multiple resource items, malformed model JSON, transient failure and expired leases, expiry and reused operation IDs, audio ownership/start idempotency, explicit reviewed-transcript submission, invalid WAV/channel/sample rate, checksum mismatch, upload expiry/renewal, terminal transcription failure, request body limits, unsigned gateway rejection, concurrent identical submissions, manual analysis retry limits, repeated worker crash limits, resource caps, and DynamoDB conditional transaction/strong-read wire contracts.

A Starlette TestClient deprecation warning recommends httpx2. It does not affect the passing tests or the separate HTTP client using actual network requests. No SDK stubs or fixtures count as real AWS inference/storage evidence.

The independent client exercised an ordinary quantity-20 water request, missing-quantity and negated requests, invalid shelter, replay/conflict, unauthorized users/inboxes, owned WAV upload, idempotent start, fixed fixture transcript and explicit scripted reviewed-text resubmission. Safe full results are in `evidence/local-http-smoke.json`. Scripted review demonstrates the API contract, not a human review interface.

Restart evidence: 2026-10-24T04:54:19.834563+00:00, request UUID `44d16d68-afad-4536-9533-a82b1e825c44`; the client deliberately discarded the first acceptance, stopped the API, restarted it, retried unchanged, and started a separate worker process. Exactly one logical request and one fixture analysis remained. See `evidence/process-restart.json`.

## Read-only AWS observations

Session rechecked at **2026-10-24T05:02:33.671484+00:00**. STS request ID `7a155d4a-50c5-41a1-82c8-7e1209ab76ba`; account `928489693154`, region `us-east-1`, role `WSParticipantRole/Participant`. Initial session check also succeeded at 04:41:02 UTC, request ID `e6048def-dfc6-4aab-bd5a-feff0ebe65ba`.

- `amazon.nova-lite-v1:0`: ACTIVE; agreement/entitlement/region AVAILABLE, authorization AUTHORIZED; on-demand listed. **No Converse invocation, inference request ID, observed model output or token usage exists yet.** JSON parsing and backend validation are implemented; native schema-constrained generation is not assumed.
- `relay-messages`: ACTIVE, on-demand, string pk/sk; Project RELAY tag. Existing stream is NEW_IMAGE and unchanged. Reserved MVP work queue and budget keys are absent. This is not a full table scan or proof that the whole table is empty.
- `relay-artifacts-928489693154-use1`: expected-account-owner checks pass, all four public-access blocks enabled, AES256 default encryption, BucketOwnerEnforced. No bucket policy and no tag set exist; these are ABSENT, not an AccessDenied finding. The proposed `cloud-mvp-v1/` prefix has no objects.
- `us-east-1_f7wyKUgiY`: existing RELAY pool; mandatory MFA, software authenticator enabled, no SMS MFA configured. Independent MFA read request ID `09825ec6-fa8e-4b69-8292-238a624c0bab`. Existing public web client has password auth but no OAuth code flow; a separate client is proposed. No users/groups/MFA settings changed.
- Participant role trust still lacks `lambda.amazonaws.com`; no role/trust change or Lambda creation attempted. Existing PowerUser permissions do not resolve the missing dedicated execution role and scoped PassRole permission.
- CloudFormation ValidateTemplate (read-only) passed, request ID `ee3a3887-d8c4-4b4c-9bfe-1bc043499446`, five parameters. This does not validate actual deployment permissions or execution behavior.

Read-only audit metadata is in `evidence/aws-readonly-audit.json`; it contains no credentials or user records. **Transcribe job IDs: none. Actual Bedrock usage: none. Actual billed charges: not reconciled.**

## Issues found and fixed locally

Initial tests exposed number parsing at a sentence-ending quantity and simultaneous SQLite API/worker startup locking. Both were fixed and subsequent tests pass. A later review added a persisted invocation counter so crash-reclaimed work cannot call Bedrock indefinitely, and conservative review flags for compound quantities/multiple items/contractions. Initial contract export required a local signing-key file; export now uses an inert AWS-mode contract configuration without AWS calls.

These resolved failures are not evidence of an AWS provider failure. No live provider success or failure has been observed.

## Reproduction and remaining gates

Run `cloud/README.md` commands for pytest, independent smoke and restart tests. Approve the bounded test proposal; provision/verify real Cognito users and run the real AWS HTTP pipeline with safe usage evidence. Resolve organizer role and hosting approval, deploy, repeat external endpoint tests, then integrate the native client. The original untracked audit/plan reports and mobile checkout were preserved; only cloud/** is committed.

## Local-link follow-up

The base path originally returned 404 even though the API routes worked. Added a base-path redirect to `/docs`, restarted the API and verified both the HTTP redirect/result and the visible RELAY Cloud API page in Safari. This navigation-only fix does not change the API contract or enable AWS activity.
