# CLOUD_DEPLOYMENT_HANDOFF — RELAY build 8

**Current status: the approved integration source is packaged and locally validated; managed AWS hosting is still blocked.** No Lambda/API Gateway HTTPS URL or deployed AWS source revision exists. The native task established the separately authorized temporary Cloudflare fallback at **https://resumes-investigated-striking-mba.trycloudflare.com** → `http://127.0.0.1:8788`. Independent authenticated read/isolation checks passed at **2026-10-24T07:34:00.865883+00:00**. This is temporary Mac-backed HTTPS, not a Lambda/API Gateway deployment. Latest read-only AWS check: **2026-10-24T07:16:42.341203+00:00**, account **928489693154**, region **us-east-1**. Handoff updated **2026-10-24T07:19:55.097035+00:00**.

## Approved source and prepared package

- Source branch: `feature/cloud-integration`.
- Exact pushed/package-approved commit: **`cfcaade434114ca584de406c9104de21e0b64008`**.
- Functional build-8 commit: `7d043b7832ebaf7541bca62c33da1f4dc396c3be`; cfcaade merges documentation only after that functional commit.
- Native checkout `/Users/thalapaneninikil/Documents/dreamerv3/RELAY-integration` was clean and still at cfcaade after packaging. No Swift/App/API/service changes were made by this AWS task.
- Artifact: `relay-lambda-cfcaade434114.zip`; 31,944,281 compressed bytes; Python 3.13 / Linux ARM64.
- SHA-256: `6cfa11535759387a579f9bb9889827cf0e8ae9085890e65137466d006f5de349`.
- Expected Lambda CodeSha256: `bPoRU1dZOHpXn5u5iJgnzw6K6QhYkOZRN0ZtAG9d40k=`.
- Local package directory: `/Users/thalapaneninikil/Documents/Codex/2026-10-23/b/outputs/relay-deployment-cfcaade434114`.
- Detailed build/validation record: `cloud/docs/DEPLOYMENT_PACKAGE.md` and `cloud/docs/evidence/packaging-cfcaade434114.json`.

The ZIP contains a source manifest and was checked against all 11 committed backend files. It includes authenticated `/v1/me`, `/v1/requests/{request_id}/history` and `/v1/requests/{request_id}/events`. Only the exact committed cloud source was exported; no uncommitted working tree or older cached ZIP was used.

## Validation and live hosting status

| Check | Result / evidence |
|---|---|
| Current account/region | PASS — STS request `c1e76e9e-112e-4ce8-86d1-284de9c3bef5`; 928489693154/us-east-1 |
| Archived-source backend tests | PASS — 35 cases, 4.42 seconds |
| Local Lambda/API Gateway v2 adapter | PASS — 17 fixture HTTP calls + one fixture worker analysis, including profile/history/progress/replay |
| Source hashes, ZIP integrity, Python syntax, ARM64 ELF headers and size limits | PASS |
| Prepared parameters | PASS — credentials/profile/cache paths removed; server-side synthetic membership retained; 30-request/five-recording caps preserved |
| CloudFormation ValidateTemplate | PASS — request `0e2a37c9-3c40-4fee-b413-69378c405a8a`; syntax only, no resources created |
| Linux Lambda runtime execution | NOT TESTED — Docker daemon unavailable |
| Dedicated execution role | FAIL — absent; current IAM request `088b483c-decb-4aab-b5cf-9fec890a98e0` |
| Execution-role trust/scoped permissions | NOT TESTED — role does not exist |
| Required dedicated-role PassRole grant | FAIL at full policy audit 06:41 UTC — only participant role itself was allowed; recheck after organizer provisioning |
| HTTP API Gateway | FAIL — zero APIs/no additional page at latest check; request `3ebadcfe-5067-426c-94b3-5df8e027389f` |
| MVP stack, API/worker Lambda and recovery schedule | FAIL — absent in full 06:41 UTC inventory; this task has not deployed them |
| Managed AWS API Gateway health/request/replay | NOT TESTED — no managed AWS endpoint |
| Temporary Cloudflare HTTPS health/authenticated reads/isolation | PASS — 12 independent GET checks; no new write/audio flow run by this audit |

**Managed AWS HTTPS API base URL: none. Deployed AWS Git revision, Lambda CodeSha256/RevisionId and hosted worker runtime status: unavailable.** Temporary Cloudflare base URL: **https://resumes-investigated-striking-mba.trycloudflare.com**; health, authenticated existing-record reads and access isolation pass. New public-URL request creation/replay/audio and native PKCE/UI testing are left to the native task; this audit did not rerun them. The hash above is for the prepared local artifact, not a deployed function. Template syntax, localhost success and a Cognito login domain are not deployment evidence.

The previous full inventory also found zero REST APIs. `relay-bedrock-metrics` is a completed CloudWatch-dashboard stack, not an API. `relay-public` is ROLLBACK_COMPLETE; its former HTTP API `t9xj4xi8k4` is DELETE_COMPLETE and must not be used. Its role-creation failures at 02:16:46 UTC explicitly denied iam:CreateRole (requests `9a3ecf95-68b4-4706-b98a-45684ae66b02` and `64b410d6-1c57-4549-8f14-3a2ecb722080`), wrapped as UnauthorizedTaggingOperation. Tagging permissions alone do not resolve the missing CreateRole permission.

## Exact organizer gate

At the full 06:41 UTC audit, WSParticipantRole had no inline policies or permissions boundary. Its attached `ws-default-policy` v1 grants PassRole only on `arn:aws:iam::928489693154:role/WSParticipantRole`; PowerUserAccess v12 excludes general IAM and does not add the dedicated-role permission. The participant trust has no Lambda service principal. Do not reuse it as a Lambda execution role or change its trust.

The attempted simulator call was denied for **iam:SimulatePrincipalPolicy** (request `b7611dd6-7f2b-48bc-91a7-6054d0b0814b`). This is not an effective PassRole simulation result. The target-role Allow is absent from the inspected identity policies, and the dedicated role remains absent in the latest direct check.

The organizer must provision `arn:aws:iam::928489693154:role/relay-cloud-mvp-execution`, with Lambda service trust and the reviewed scoped permissions, then grant the participant PassRole only for that ARN with `iam:PassedToService=lambda.amazonaws.com`. Exact reviewable documents:

- `cloud/docs/ORGANIZER_REQUEST.md`
- `cloud/infra/organizer-role-trust.json`
- `cloud/infra/organizer-execution-policy.json`
- `cloud/infra/organizer-participant-passrole.json`

These are proposals, not installed permissions. This task made no IAM, MFA-setting or hosting changes.

## Native Cognito configuration and private test access

The following configuration was verified directly at 06:41–06:43 UTC; subsequent MFA sign-in also passed.

| Setting | Value |
|---|---|
| Pool | `us-east-1_f7wyKUgiY` |
| Public client | `RELAY-Cloud-MVP-Native` / `dfulb5lau8283nlgil7ddu36i` |
| Issuer | `https://cognito-idp.us-east-1.amazonaws.com/us-east-1_f7wyKUgiY` |
| Login domain | `https://relay-mvp-928489693154.auth.us-east-1.amazoncognito.com` — ACTIVE |
| Authorize / token paths | `/oauth2/authorize` / `/oauth2/token` on that login domain |
| Native callback / logout | `relay://oauth/callback` / `relay://oauth/signout` |
| Additional local callback | `http://localhost:8400/callback` |
| Scopes / flow | `openid email`; authorization code; native client uses PKCE S256 and validates state |
| Client secret | None |
| MFA | ON; software authenticator enabled; four synthetic users have TOTP enabled/preferred |
| Self sign-up | Disabled; enrolled/admin-created accounts only |
| Token lifetime | Access/ID 60 minutes; refresh 1 day; revocation enabled |

Configuration request IDs: client `a9b656c1-ba6a-471a-b3d2-e2678632c3b1`, domain `7c3dad69-6c98-4a02-b1a6-a6abfbd3ffc6`, MFA `c493d139-1a22-494a-96a9-74c984aad6d6`. Native PKCE on physical phones remains unverified; passing scripted MFA or installing build 8 does not establish that flow.

Use actor `test-requester-a` for ordinary requests, `test-dispatcher-a` for shelter-a progress/replies, or the corresponding `-b` actors for shelter-b isolation tests. They belong to synthetic-demo-01 through server-controlled membership, not an agency dispatcher-group grant.

The user can privately open the existing owner-only local account store on this Mac:

```text
/Users/thalapaneninikil/Documents/Codex/2026-10-23/b/work/relay-runtime/live/demo-identities.private.json
```

Select only the needed actor. Use its username/password in the Cognito hosted sign-in opened by the app's PKCE flow; import its already-enrolled TOTP setup locally into the user's authenticator if needed. Do not reset MFA or paste the private record into chat, issues, screenshots, source or mobile configuration. The file is mode 0600 inside a mode-0700 directory. The `.invalid` test emails cannot receive recovery mail.

The companion private `aws-test-tokens.json` is for local operator tests only. Requester-A and dispatcher-A were refreshed at 06:51:50 UTC; their tokens expire. No token file, password, MFA seed, AWS credential or signed upload URL is included in this handoff or package.

## Verified Swift integration and shared limits

The native task reports 43 Swift tests, the Swift→AWS text/audio/profile/history/replay flow, build-8 installation/launch on both original phones with data preserved, and internal TestFlight Testing status. This AWS task independently reran the **35 backend tests from the committed source** and independently read the known AWS results. It did not repeat Swift builds or physical-device tests.

Independent strongly consistent readback at **2026-10-24T07:02:28.963938+00:00** confirmed:

| Native attempt | Request UUID | Stored result |
|---|---|---|
| Initial attempt interrupted later by expired auth | `a9622506-46c2-4870-ac10-ee6d90525129` | accepted / ready_for_review |
| Completed Swift text flow | `2774002c-8238-4311-871c-cf820d3a2c92` | accepted / ready_for_review |
| Completed Swift reviewed-audio flow | `16764f77-3780-48b6-bd11-8f2a58eb9835` | accepted / ready_for_review |

**Correction retained:** the first expired-token attempt was not a zero-write failure. It had already accepted and processed the first request above before later authentication failed.

Transcription `99599e0d-df75-4712-b28c-522bb4be669b` and its real Transcribe job are completed. Both completed Swift flows have persisted history revision 3, three unique events, and dispatcher-reported accepted→in_progress→completed. `resource_allocation_verified` remains false; this is reported progress, not proof of physical delivery or automatic resource allocation.

Latest shared counters are **15 requests / 30 and 2 recordings / 5** (also reconfirmed in the packaging read-only check). Fifteen request slots and three recording slots remain at that timestamp. This packaging run added **zero** accepted requests, model calls, transcription jobs or infrastructure writes. The native task reports no further paid tests planned. Recheck these shared durable counters before any later test; counters are not a dollar billing statement.

Native local testing uses **http://127.0.0.1:8788**; the earlier 8787 server/worker was preserved. Neither address is a deployed HTTPS API or reachable as localhost from a separate iPhone. Carrier-to-cloud ingestion is explicitly not implemented. No source files or running servers were overwritten by packaging. The native task owns the separately authorized temporary tunnel and physical-login/audio test workflow. The AWS task verified its public hostname against the running cloudflared process/log and verified Cognito-protected reads. A working tunnel must not be described as a Lambda/API Gateway deployment.

## Temporary HTTPS verification — current demo endpoint

**Base URL:** https://resumes-investigated-striking-mba.trycloudflare.com

**Origin:** `http://127.0.0.1:8788`, with the existing AWS-backed database and worker. The active cloudflared process targeted that origin and its local log contained this exact public hostname. All 11 backend files on disk match approved source `cfcaade434114ca584de406c9104de21e0b64008`; build-9 native UI/configuration work is separate and was not packaged or modified by this AWS task. This source comparison does not assert an AWS deployed revision or prove the in-memory process revision through a dedicated endpoint.

Verification window: **2026-10-24T07:33:56.347122+00:00 → 2026-10-24T07:34:00.865883+00:00**. Requests used the public HTTPS hostname with certificate verification and no redirect following. Only existing records were read.

| Check | HTTP | Result | Safe Cloudflare request correlation |
|---|---|---|---|
| public_health | 200 | PASS | `a4f74bd769cc7b83-SJC` |
| missing_token_rejected | 401 | PASS | `a4f74bd9fed07b83-SJC` |
| invalid_token_rejected | 401 | PASS | `a4f74bdb9a197b83-SJC` |
| requester_a_profile | 200 | PASS | `a4f74bdc0b097b83-SJC` |
| requester_a_directory | 200 | PASS | `a4f74bdc8c197b83-SJC` |
| existing_persisted_request_read | 200 | PASS | `a4f74bddaeae7b83-SJC` |
| existing_history_read | 200 | PASS | `a4f74be13e707b83-SJC` |
| fresh_requester_b_profile | 200 | PASS | `a4f74be9aff37b83-SJC` |
| requester_b_directory | 200 | PASS | `a4f74bea38f37b83-SJC` |
| valid_other_user_cannot_read_request | 404 | PASS | `a4f74beaea287b83-SJC` |
| valid_other_user_cannot_read_history | 404 | PASS | `a4f74bec3cfe7b83-SJC` |
| requester_cannot_use_dispatcher_inbox | 403 | PASS | `a4f74bed9fb37b83-SJC` |

Requester-B completed a fresh SOFTWARE_TOKEN_MFA challenge in memory (Cognito request `c88cf975-5cb1-481f-a679-c5df683a58cc`). Its valid session could read its own profile/shelter-b directory but could not read requester-A's existing request/history or use a dispatcher inbox. This closes the earlier expired-token gap: the isolation result is **404/403 with a valid other-user token**, not merely 401 with an expired token. The temporary session was not saved; no shared token file, config, worker or backend was changed.

The existing request `2774002c-8238-4311-871c-cf820d3a2c92` returned its persisted real Bedrock result and revision-3 history. No new request was created, no POST/replay was issued, no audio was uploaded, and no model/transcription job was invoked in these checks. Shared counters were unchanged at **15/30 requests and 2/5 recordings**.

The native task reports successful build-9 builds with this configured endpoint and a synthetic-WAV importer; the user is completing Cognito PKCE/MFA before native UI testing. Those native/physical outcomes are **pending**, not inferred from this HTTP probe. Follow the native task for the new public-URL write/audio/UI evidence.

This is a temporary quick tunnel: availability depends on the Mac, cloudflared process, origin API and worker; a restart can yield a different hostname. Treat it as the authorized demo fallback, not durable AWS hosting. The Lambda artifact remains unuploaded and undeployed, with the organizer role/PassRole gate unchanged.

Sanitized evidence: `cloud/docs/evidence/temporary-https-readonly-20261024.json` and `temporary-https-source-20261024.json`.

## Exact next step for managed AWS hosting

The temporary HTTPS demo can proceed under its existing authorization while the native task completes PKCE/MFA and public-URL text/audio UI checks within the shared limits. That path does not require pretending the organizer role exists.

The source/packaging gate is **cleared for cfcaade**. The remaining immediate gate is the organizer-provided scoped role/PassRole and hosting approval. Once those exist:

1. Recheck actual role trust/policies and scoped PassRole; confirm cfcaade remains the native task's agreed deployment source.
2. Upload the prepared ZIP to the recorded source-specific S3 key, deploy the exact reviewed template/parameters, and record the actual stack/function statuses and HTTPS URL. Nothing has been uploaded yet.
3. Compare deployed Lambda CodeSha256 to the artifact value above. Update the server `public_base_url` and native client base URL from localhost to that actual endpoint.
4. Run the approved authenticated one-text-request, persisted-result and same-ID replay checks against the hosted URL, plus profile/history/events compatibility. Then verify native PKCE and physical-phone cloud access.

The prepared parameter file currently retains a localhost public_base_url and is clearly marked for this post-deployment update. Do not invent a hosted URL, deploy an older ZIP, package new uncommitted edits, broaden IAM or disable MFA to bypass the gate.

## Evidence

Current packaging: `cloud/docs/evidence/packaging-cfcaade434114.json`, `packaging-adapter-cfcaade434114.json`, `packaging-aws-readonly-cfcaade434114.json`.

Earlier full deployment/auth/policy audit: `cloud-deployment-audit-20261024.json`, `cloud-deployment-readiness-20261024.json`, `cloud-deployment-source-state-20261024.json`, `cloud-deployment-session-refresh-20261024.json`.

Native readback and follow-up hosting check: `native-integration-readback-20261024.json`, `native-followup-hosting-20261024.json`.
