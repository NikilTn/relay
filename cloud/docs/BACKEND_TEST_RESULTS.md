# Backend test results — real AWS verification, 2026-10-24 UTC

**The actual Cognito → S3 → Transcribe → reviewed request → Nova Lite → DynamoDB flow passes through the locally hosted API.** The earlier fixture-only report is superseded by this evidence. The live run was authorized after the user requested actual service testing in response to the bounded $2 proposal. Public hosting and native integration remain unverified.

| Area | Status | Evidence / limits |
|---|---|---|
| Automated backend tests | PASS | 30 pytest cases, 2.78 seconds; includes regression checks from real model failures |
| Local fixture HTTP/restart tests | PASS | Retained earlier evidence; not counted as AWS proof |
| Real Cognito authentication | PASS | Four synthetic users; TOTP setup and repeated SOFTWARE_TOKEN_MFA sign-in; authenticated API access |
| Access isolation / idempotency | PASS | Actual HTTP requests with real Cognito tokens; wrong-owner/wrong-shelter/requester privilege denials, identical replay and changed-content conflict |
| Real Bedrock | PASS | On-demand Converse with amazon.nova-lite-v1:0; actual outputs and usage recorded |
| Real Transcribe | PASS | One real batch job completed; raw transcript independently matched private S3 output |
| Private S3 upload/sealing | PASS | Presigned POST worked; three owned objects verified AES256 and expected-account ownership; sealed SHA-256 matched |
| Durable DynamoDB | PASS | Accepted requests/results persisted; six selected results matched independent strongly consistent SDK reads; all 12 test requests enumerated in the owned inbox |
| AWS process crash/restart | PASS | API killed after commit, restarted, unchanged replay returned existing request; separate worker recovered one logical request and one model analysis |
| API reachability on this Mac | PASS | http://127.0.0.1:8787; mode aws, storage dynamodb; `/` opens `/docs` |
| Lambda artifact/template | PASS (build/syntax only) | Linux arm64 packaging and prior AWS ValidateTemplate; no deployment claim |
| Public API / Lambda runtime | NOT TESTED | Dedicated execution role absent, no hosted stack or public tunnel |
| Native PKCE browser flow | NOT TESTED | Public client/domain/code flow configured; scripted password + TOTP was tested |
| Native app / physical iPhones / offline gateway | NOT TESTED | No Swift/signing/transport changes; this endpoint is loopback-only |
| Noisy human-speech accuracy | NOT TESTED | Short synthetic/TTS recording; a shelter-name transcription error occurred |

## Actual sample flow and results

Audio: 62,464-byte mono PCM16 WAV, 16 kHz, 1.824 seconds, generated locally with macOS speech. SHA-256 `9d5ceb99bb4ab2f3375cf0d2bdcf3286f42fa1155bc3c87bcf3b94475b6f2271`.

Spoken: **“Shelter A needs two water packs.”**

Actual Transcribe output: **“Sheltering needs 2 water packs.”**

The initial independent client submitted the returned text through the same request API and received a quantity-2 water-pack proposal. The agent then explicitly reviewed the known sample, corrected the shelter name to **“Shelter A needs 2 water packs.”**, and submitted a separate synthetic reviewed request. Its model result was item `water_packs`, quantity `2`, unit `pack`, shelter `shelter-a`, negated `false`, no missing fields, and `ready_for_review`. It is durably accepted, with `allocation_authorized: false`; nothing was allocated or fulfilled. This was an agent-reviewed test, not a native human review UI.

The full HTTP smoke ran **2026-10-24T05:36:49.128804+00:00 → 2026-10-24T05:37:14.548931+00:00**. The corrected reviewed result completed **2026-10-24T05:38:35.863525+00:00**.

| Model input | Result | Bedrock request ID | Input / output tokens |
|---|---|---|---|
| SYNTHETIC: Shelter A needs 20 water packs. | ready_for_review | `bfb5208e-7d18-442d-a661-b8dac8b13bcc` | 491 / 50 |
| Shelter A needs water packs. | needs_review | `ae1b5709-5128-432a-97f8-d0de0c2b80bb` | 484 / 55 |
| Do not send 20 water packs to Shelter A. | needs_review | `0dc66d42-5591-4f6d-a112-2a6fb2a401c5` | 489 / 53 |
| Sheltering needs 2 water packs. | ready_for_review | `ad7e2eef-9c2f-4f22-bea1-50ebb4f9979f` | 486 / 47 |
| Shelter A needs 2 water packs. | ready_for_review | `f0d88c90-3d37-47a5-92f2-e2ee75259ff9` | 486 / 48 |
| Shelter A needs 7 blankets. | ready_for_review | `b127b37e-051c-4265-8362-c60f1853848d` | 485 / 45 |

Model: `amazon.nova-lite-v1:0`, region `us-east-1`, Converse API, temperature 0, maximum 512 output tokens. A system instruction and explicit flat output contract were tested; native JSON-schema enforcement is **not** used or assumed.

Transcription UUID: `4c846e02-915b-4512-a2b9-767dcb7d1728`. Job: `relay-mvp-4c846e02-915b-4512-a2b9-767dcb7d1728`. Start request ID: `9d614d34-1d6c-45a9-9a65-d98858208166`; completed poll request ID: `fff11b02-ae90-4725-b930-cbb272149a94`. Provider status COMPLETED was independently confirmed. Only the known owned S3 output key was read; arbitrary provider-returned URLs were not fetched.

Corrected request UUID: `41332d51-6592-4b8a-a264-8dc9cbcf8ada`. Restart request UUID: `b75af109-b98a-4dcd-a4e5-15ae3feb84c4`. The restart test completed `2026-10-24T05:39:08.083402+00:00` and observed exactly one logical request and one model attempt. Direct storage verification completed at `2026-10-24T05:40:38.643950+00:00` with the work queue empty.

## Live defects found and handling

Initial real responses used Markdown fences or echoed the input envelope. The original strict parser rejected them and retained durable acceptance with needs_review. System instructions were revised to separate input data from the flat output contract; ordinary requests then returned valid JSON.

Nova Lite also invented quantity 1 for text with no quantity. The backend caught quantity_not_grounded. Validation was strengthened to clear invented quantity values and explicitly mark missing quantity from the source text. Missing quantity and negation now remain explicit even when the model emits malformed JSON. One missing-quantity response still ended with an extra `]`; it correctly produced needs_review with invalid_model_output and missing_quantity. This remains a model reliability limitation, not silently repaired or described as valid extraction. The final end-to-end test passes because the required safe review state is reached.

The real transcript misheard “Shelter A” as “Sheltering.” The explicit review/edit step corrected it. Do not infer ASR accuracy from plumbing success. Typed requests remain independent of speech.

MFA verification found that registering/verifying a software token did not populate the user's enabled-MFA list until preference activation. Provisioning now explicitly enables/prefers TOTP only for the four new synthetic users. Each was then signed in again with an actual SOFTWARE_TOKEN_MFA challenge. The original pool still requires MFA; original users, client and dispatcher group were not changed.

Earlier local-only issues (sentence-ending number parsing and concurrent SQLite initialization) remain fixed. One Starlette TestClient deprecation warning persists; tests and the separate HTTP client pass.

## Authentication, resources and usage

Account `928489693154`, region `us-east-1`. Pre-write STS request ID `3f0fa02d-da48-4c30-8edf-b7c3ce506878`; ownership/schema/MFA checks passed and the reserved MVP namespaces were empty before writes. Public app client `dfulb5lau8283nlgil7ddu36i`, domain `relay-mvp-928489693154.auth.us-east-1.amazoncognito.com` ACTIVE. Authentication verification timestamp `2026-10-24T05:43:16.476975+00:00`. Requester-A repeat MFA auth request ID `3a4dfcde-c5f0-4e76-b6eb-7345bef8b505`. No client secret, bearer token, password, TOTP seed or AWS credentials are in committed evidence.

Usage observed: **12 accepted synthetic requests, 16 real model calls including 4 diagnostic calls, 6,948 input tokens, 1,181 output tokens, one transcription job.** This includes failed formatting diagnostics. Actual billed charges/credits are not reconciled; see COST_AND_CLEANUP.md and RESOURCE_MANIFEST.json. The run remains within the proposed 30-request/five-recording scope; no hosted services, TTS API, custom ASR or training were created.

## Remaining hosting gate

`relay-cloud-mvp-execution` does not exist: IAM returned `NoSuchEntity` at `2026-10-24T05:37:38.946882+00:00`, request ID `7ec6347a-02d0-47e6-849f-2fcc4ca37dff`. The participant role is not a suitable Lambda execution role; its trust was not weakened. No Lambda/API Gateway deployment was attempted. Obtain the organizer role/scoped PassRole, approve hosting scope, deploy, rerun the external endpoint tests, then integrate and test native PKCE and physical iPhones.

## Reproduction / evidence

- `scripts/smoke_client.py` against the real API with the private Cognito token file, the committed synthetic WAV and `--allow-chargeable-aws`.
- `scripts/aws_restart_smoke.py` with the private AWS config/tokens and the explicit paid-test flag; stop other workers first. It creates one new synthetic request, kills only its own API process, replays unchanged and starts a separate worker.
- `scripts/verify_live_storage.py` performs independent read-only AWS checks of the smoke/review/restart records and known owned S3/job objects.
- `evidence/aws-live-http-smoke.json`, `aws-live-reviewed-audio.json`, `aws-live-restart.json`, `aws-live-storage.json`, `aws-live-authentication.json` and `aws-live-usage.json` contain safe actual results and request IDs.
- Earlier failure/diagnostic evidence is retained as `aws-*-diagnostic*.json` and `aws-*-format-failure.json`; it is not presented as final success.

All implementation/evidence changes are under cloud/**. The mobile checkout and original untracked reports remain preserved.
