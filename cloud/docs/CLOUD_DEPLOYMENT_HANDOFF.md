# CLOUD_DEPLOYMENT_HANDOFF — RELAY

**Current verdict: hosting is blocked; no deployed HTTPS API exists.** This is a fresh AWS inspection, not a restatement of the earlier template or local-flow report. Account **928489693154**, configured/audited region **us-east-1**. Inventory completed **2026-10-24T06:41:33.163381+00:00**; resource readiness and fresh Cognito MFA sign-in completed **2026-10-24T06:42:59.883743+00:00**. Handoff written **2026-10-24T06:48:41.746878+00:00**.

The existing data/auth/model services are ready and the earlier real local API flow remains documented separately. The execution role, scoped PassRole grant and hosted backend are still missing. No IAM permissions, MFA settings, backend implementation or native files were changed in this audit. No new model/audio request was run, and no artifact was packaged or deployed.

## Current deployment state and source

| Item | Timestamped result | Evidence |
|---|---|---|
| Active account/session | PASS — 2026-10-24T06:41:33.163381+00:00 | `WSParticipantRole/Participant`, account 928489693154; STS request `1e7e8f8b-3d19-4641-95eb-9cf12453fb33` |
| Region | PASS — 2026-10-24T06:41:33.163381+00:00 | Both profile and inspected AWS service region are us-east-1 |
| `relay-cloud-mvp-execution` exists | FAIL — absent at 2026-10-24T06:41:33.163381+00:00 | `NoSuchEntity`; IAM request `537c52c1-faba-41f2-95fc-9e20c0609f19` |
| Execution-role Lambda trust / scoped policy | NOT TESTED — role absent | There is no role policy/trust to validate; expected reviewed documents are listed below |
| Required participant PassRole grant | FAIL — current policy inspection | Only WSParticipantRole itself is allowed; dedicated role ARN has no grant |
| IAM effective-policy simulation | NOT TESTED — simulator access denied | `iam:SimulatePrincipalPolicy` denied, request `b7611dd6-7f2b-48bc-91a7-6054d0b0814b`; this is not a PassRole simulation result |
| `relay-cloud-mvp` stack | FAIL — absent | DescribeStacks says stack does not exist; request `9467e86a-4549-4db6-a0d2-93b189e3cbf0` |
| API Gateway | FAIL — no deployed APIs | Fresh paginated inventory: 0 HTTP/WebSocket APIs and 0 REST APIs in us-east-1 |
| `relay-cloud-mvp-api` Lambda | FAIL — absent | ResourceNotFoundException; request `192112f2-6d30-4cbc-89da-f87bea63e92c` |
| `relay-cloud-mvp-worker` Lambda | FAIL — absent | ResourceNotFoundException; request `a2aade24-c8d3-4567-8f23-cae3c49130f1` |
| Recovery schedule | FAIL — absent | `relay-cloud-mvp-recovery` not found; request `02d099fa-12f2-4573-95f5-3f04496b4c16` |

**HTTPS API base URL: none. Deployed source commit: none. Lambda CodeSha256/RevisionId and worker runtime status: unavailable because neither function exists.** No deployment is inferred from a valid template, a Cognito domain, a retained bucket, a CloudWatch dashboard or the localhost service.

Two other RELAY stacks are visible:

- `relay-bedrock-metrics`: CREATE_COMPLETE; contains a CloudWatch dashboard, not a backend API.
- `relay-public`: ROLLBACK_COMPLETE. Its former HTTP API `t9xj4xi8k4` is DELETE_COMPLETE; do not use that historical ID as a live endpoint. Its web bucket was retained, which does not establish an API deployment. The historical ApiRole and WorkerRole creation failures at 2026-10-24 02:16:46 UTC explicitly say **iam:CreateRole has no identity-based Allow** (IAM requests `9a3ecf95-68b4-4706-b98a-45684ae66b02` and `64b410d6-1c57-4549-8f14-3a2ecb722080`). The error was wrapped as UnauthorizedTaggingOperation; adding only tagging permissions would not resolve the underlying CreateRole denial.

Only one Lambda exists in the region-wide inventory and it is not a RELAY function; it was not modified.

## Exact permission blocker

The participant has no inline policies or permissions boundary. Current attached policies are `ws-default-policy` v1 and `PowerUserAccess` v12.

`ws-default-policy` grants `iam:PassRole` only on:

```text
arn:aws:iam::928489693154:role/WSParticipantRole
```

It does not grant passing `arn:aws:iam::928489693154:role/relay-cloud-mvp-execution`. PowerUserAccess excludes general IAM actions and its explicit IAM exceptions do not add that permission. The participant's current trust also has no Lambda service principal. Therefore reusing the participant as a Lambda role does not solve this blocker and must not be done.

The simulator call itself was denied for lack of `iam:SimulatePrincipalPolicy`; no successful effective-policy simulation or deployment/PassRole operation is claimed. The required target-role grant is demonstrably absent from the inspected identity policies. Normal dedicated-role creation is also not allowed by these policies, consistent with the older stack's recorded denial.

The organizer must provide the dedicated role with Lambda-only service trust, reviewed scoped execution permissions, and a participant PassRole grant restricted to that exact ARN with `iam:PassedToService = lambda.amazonaws.com`. Reviewable request and JSON documents already exist:

- `cloud/docs/ORGANIZER_REQUEST.md`
- `cloud/infra/organizer-role-trust.json`
- `cloud/infra/organizer-execution-policy.json`
- `cloud/infra/organizer-participant-passrole.json`

These are requested configurations, not installed policies. This audit did not broaden IAM, weaken MFA, change any trust policy or create a public server.

## Requested HTTPS endpoint tests

| Test against the deployed HTTPS API | Current result |
|---|---|
| Health | NOT TESTED — no deployed endpoint |
| Authorized shelters using real Cognito access token | NOT TESTED — no deployed endpoint |
| One new synthetic text request | NOT TESTED — no deployed endpoint; no request created |
| Persisted Bedrock result | NOT TESTED on a hosted endpoint |
| Replay of the same request ID/content | NOT TESTED on a hosted endpoint |

**Fresh Cognito authentication itself: PASS.** Existing actor `test-requester-a` returned SOFTWARE_TOKEN_MFA, completed its current authenticator challenge, and received a one-hour access token. InitiateAuth request `2329c66e-8d08-4679-a926-ef6b8c304cd9`; authentication request `b870a1d4-52b2-4bab-850a-d319065b1d38`. The token stayed in the existing private local store. No password/MFA reset or enrollment was performed.

A separate read of `http://127.0.0.1:8787/v1/health` still reports mode `aws`, storage `dynamodb`. That is **Mac-only liveness**, not the requested hosted verification. Its current OpenAPI does not expose `/v1/me`, `/v1/requests/{request_id}/history` or `/v1/requests/{request_id}/events`; the native task's new endpoints must be included in the future package. Earlier local real-AWS inference/transcription successes are historical evidence in BACKEND_TEST_RESULTS.md and are not counted as hosted tests here.

Fresh durable usage counters remain **12/30 request records and 1/5 transcription records**. This audit added zero accepted requests, zero Bedrock calls and zero Transcribe jobs. At this counter snapshot, the one-request HTTPS smoke remains within the earlier limits once a hosted URL exists; 18 request slots and four audio slots remained. The native task is subsequently running its own approved local Swift-client flow, so reread these shared durable counters before any additional test. Billing is not reconciled by these record counts.

## Confirmed native Cognito configuration

| Setting | Current AWS value |
|---|---|
| Region | `us-east-1` |
| User pool | `us-east-1_f7wyKUgiY` |
| Public client | `RELAY-Cloud-MVP-Native` |
| Client ID | `dfulb5lau8283nlgil7ddu36i` |
| Issuer | `https://cognito-idp.us-east-1.amazonaws.com/us-east-1_f7wyKUgiY` |
| Login base | `https://relay-mvp-928489693154.auth.us-east-1.amazoncognito.com` — ACTIVE |
| Authorize endpoint | `https://relay-mvp-928489693154.auth.us-east-1.amazoncognito.com/oauth2/authorize` |
| Token endpoint | `https://relay-mvp-928489693154.auth.us-east-1.amazoncognito.com/oauth2/token` |
| Native callback | `relay://oauth/callback` |
| Native logout redirect | `relay://oauth/signout` |
| Additional configured local callback | `http://localhost:8400/callback` |
| Scopes | `openid email` |
| OAuth flow | Authorization code; native client should use PKCE S256 and validate state |
| Client secret | None |
| MFA | Required (ON), software authenticator enabled |
| Self sign-up | Disabled; admin-created/enrolled accounts only |
| Access / ID token lifetime | 60 minutes |
| Refresh token lifetime | 1 day; token revocation enabled |

Client configuration request `a9b656c1-ba6a-471a-b3d2-e2678632c3b1`; domain request `7c3dad69-6c98-4a02-b1a6-a6abfbd3ffc6`; MFA configuration request `c493d139-1a22-494a-96a9-74c984aad6d6`. The Cognito domain is a **login service**, not the application's API base URL. Native PKCE callback behavior has not been tested by this AWS audit.

All four existing synthetic accounts are enabled, CONFIRMED, and have SOFTWARE_TOKEN_MFA enabled/preferred. Intended server membership remains:

| Local actor | Synthetic membership |
|---|---|
| `test-requester-a` | Requester, synthetic-demo-01, shelter-a |
| `test-requester-b` | Requester, synthetic-demo-01, shelter-b |
| `test-dispatcher-a` | Dispatcher, synthetic-demo-01, shelter-a |
| `test-dispatcher-b` | Dispatcher, synthetic-demo-01, shelter-b |

### Private access to an enrolled test account

Use `test-requester-a` for an ordinary requester test, or the matching dispatcher actor for its shelter inbox. The user can privately open the existing owner-only local account store on this Mac:

```text
/Users/DEVELOPER/Documents/Codex/2026-10-23/b/work/relay-runtime/live/demo-identities.private.json
```

Select only the needed actor's record. Use its username/password in the Cognito hosted sign-in opened by the app's PKCE flow. Its already-enrolled TOTP authenticator is required; the corresponding setup material is kept in that same private record and can be imported locally into the user's authenticator. Do not reset MFA or paste that record into chat, issues, source, screenshots or mobile configuration. The file is mode 0600 inside a mode-0700 directory. This handoff does not reproduce any credential or setup material.

For automated backend tests, the existing private `aws-test-tokens.json` in that directory is usable only as a local operator artifact. Tokens expire; requester-A and dispatcher-A were refreshed during this audit. The other actors were not refreshed. Never ship that file, AWS credentials, TOTP material or a shared test token in the app. No secrets are needed in `cloud/examples/public-client-config.json`. The `.invalid` test emails are synthetic and cannot receive recovery mail.

## Ready infrastructure and coordinated next step

Fresh reads confirm `relay-messages` is ACTIVE with string pk/sk and on-demand billing; the private artifacts bucket has all four public-access blocks and AES256 default encryption; Cognito is configured as above; Nova Lite availability is AUTHORIZED/AVAILABLE. No new inference was run during this read-only readiness check.

[Backend PR #1](https://github.com/NikilTn/relay/pull/1) currently carries backend implementation commit `db7d03a4fb106969cf7aac9538d68b903dd8f4a5`. That is source provenance only, not a deployment revision.

The native task **Build and Test RELAY Offline P2P** confirmed:

- Integration checkout: `/Users/DEVELOPER/Documents/dreamerv3/RELAY-integration`.
- Branch: `feature/cloud-integration`; observed HEAD `c19b4358b4fd1d24a25b7ff2becccd0620e110cf` merges native build-7 `f0388913d09a7e4004cb031525d6338a086eda6a` with backend `db7d03a4fb106969cf7aac9538d68b903dd8f4a5`.
- Profile/history/events backend changes are **uncommitted and not package-ready**. The native task reports 35 fixture tests passing; this audit did not rerun that suite or modify its files.
- It will provide a tested integration commit when ready. No hosted URL is known to it.

**Do not deploy the cached older cloud-mvp ZIP or package an uncommitted snapshot.** No packaging was performed here.

The exact next sequence is:

1. Organizer supplies the dedicated role and narrow PassRole permission; recheck its real trust/scoped permissions without altering the participant trust.
2. Native task supplies the tested, committed `feature/cloud-integration` revision containing `/v1/me`, history and request events, along with its current API contract. Confirm that exact commit and clean packaging state with it.
3. With hosting scope approved separately from the prior local-AWS test allowance, package that agreed revision, record the Git commit and artifact hash/S3 key, and deploy the reviewed template using the supplied role. Do not overwrite native API/service files or reuse stale build artifacts.
4. Record CloudFormation status, real HTTPS URL, Lambda CodeSha256/RevisionId/source mapping and worker schedule/status. Run the requested authenticated one-request/replay/persistence smoke against that URL, then verify native profile/replies/progress compatibility.

The immediate infrastructure blocker is organizer role/PassRole provisioning; the parallel source gate is the native task's tested commit. This audit reports readiness and blockers without changing either.

## Sanitized audit evidence

`cloud/docs/evidence/cloud-deployment-audit-20261024.json`, `cloud-deployment-readiness-20261024.json` and `cloud-deployment-source-state-20261024.json` retain the fresh resource/policy/configuration observations, safe request IDs and source snapshot. No credentials, bearer tokens, MFA seeds, signed upload URLs or Lambda download URLs are included.

## Native-task coordination follow-up

At 2026-10-24T06:51:50.548526+00:00, the existing requester-A and dispatcher-A both completed fresh SOFTWARE_TOKEN_MFA sign-in. Only the existing owner-only token file was updated atomically; no credential values were sent to the native task or written here. Safe authentication request IDs: requester-A `d2e9f511-8af6-4144-be1f-e16b81d06e08`; dispatcher-A `93a0a5c4-9e84-4d08-a3e5-b0fcb5a0284d`. Evidence: `cloud/docs/evidence/cloud-deployment-session-refresh-20261024.json`.

The native task reports a new-source API on **http://127.0.0.1:8788** for its Swift-client test, preserving the earlier localhost:8787 server/worker. This is a local integration test, not a deployed HTTPS endpoint. It reports 43 Swift and 35 fixture backend tests passing; those were not independently rerun by this audit. Its one-text/one-synthetic-WAV live test will consume the shared approved limits. The hosting findings and no-packaging gate remain unchanged.
