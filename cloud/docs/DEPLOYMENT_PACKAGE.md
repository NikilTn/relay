# RELAY build-8 deployment package — prepared, not deployed

**Source:** `cfcaade434114ca584de406c9104de21e0b64008` (`feature/cloud-integration`). Functional build-8 commit: `7d043b7832ebaf7541bca62c33da1f4dc396c3be`. Origin and the clean native integration checkout matched this exact SHA. Only committed cloud/** content was exported into an isolated build directory. The native checkout and backend API/service files were not modified.

**Artifact:** `relay-lambda-cfcaade434114.zip` — 31,944,281 bytes compressed, 69,902,120 bytes uncompressed. Target: Python 3.13, Linux ARM64.

**SHA-256:**

```text
6cfa11535759387a579f9bb9889827cf0e8ae9085890e65137466d006f5de349
```

Expected AWS Lambda `CodeSha256` (base64):

```text
bPoRU1dZOHpXn5u5iJgnzw6K6QhYkOZRN0ZtAG9d40k=
```

The ZIP includes `RELAY_BUILD_INFO.json` with the exact commit, dependency-lock hash and every backend file hash. The external ARTIFACT_MANIFEST.json records the final ZIP hash and validation results. No credentials, private runtime configuration, tokens, signing keys, MFA seeds or test-account files are bundled.

| Check | Result |
|---|---|
| Exact Git source match | PASS — all 11 backend files match cfcaade |
| Archived-source backend tests | PASS — 35 cases, 4.42 seconds |
| API Gateway v2 / Mangum adapter | PASS — 17 local fixture HTTP operations, one fixture worker analysis; includes profile, request replay, history and idempotent progress events |
| Linux ARM64 native library headers | PASS — all packaged ELF binaries are 64-bit AArch64 |
| ZIP integrity/path checks and Python syntax | PASS |
| Lambda package/environment size checks | PASS — environment map estimate 1025 bytes |
| Prepared parameter hygiene | PASS — AWS profile/credential/cache paths removed; 30-request/five-recording limits preserved |
| AWS ValidateTemplate | PASS — request `0e2a37c9-3c40-4fee-b413-69378c405a8a` |
| Linux Lambda runtime execution | NOT TESTED — Docker daemon is not running on this Mac |
| Hosted API/Lambda execution | NOT TESTED — no role or hosted endpoint |

The local adapter check ran on macOS using the pinned dependency environment and synthetic fixture providers. It does not substitute for Linux or hosted AWS execution. Template validation does not create resources or prove deployment permissions.

## Prepared files

- `relay-lambda-cfcaade434114.zip`: complete deployment ZIP.
- `ARTIFACT_MANIFEST.json`: source, hashes, binary checks and package metadata.
- `template.yaml`: exact template from the source commit.
- `parameters.json`: non-secret server-side CloudFormation parameters, retained owner-only locally. It contains synthetic membership IDs and public Cognito configuration, not login credentials; it is not mobile-app configuration.
- `requirements.lock`: exact pinned dependency list.
- `LOCAL_ADAPTER_VALIDATION.json` and `AWS_READ_ONLY_VALIDATION.json`: sanitized validation evidence.

Reserved future S3 target (not uploaded):

```text
s3://relay-artifacts-928489693154-use1/cloud-mvp-v1/deploy/cfcaade434114ca584de406c9104de21e0b64008/relay-lambda.zip
```

`public_base_url` in the prepared server settings retains the current localhost value. Replace it with the real HTTPS endpoint after deployment, and update the native app's separate base URL. No hosted URL has been fabricated or inferred from this configuration.

## Remaining gate

Latest AWS check at **2026-10-24T07:44:57.246002+00:00**, account **928489693154**, region **us-east-1**:

- `relay-cloud-mvp-execution` remains absent (`NoSuchEntity`, request `8f367161-9509-44ed-96ce-c644c1d75d53`).
- HTTP API inventory is empty (request `06137d8a-f5d9-470b-a2c5-553604df7811`); the MVP stack and API/worker Lambda functions remain absent.
- Shared counters are **17/30 requests and 3/5 recordings** after the native task's bounded public-HTTPS flow. This packaging/audit work made zero model/transcription calls and zero infrastructure writes.

The earlier full audit found no MVP stack, API/worker Lambdas or recovery schedule, and no participant PassRole grant for the dedicated role. The source gate is now cleared: the native task approved this exact commit for local packaging. Deployment still requires the organizer-created Lambda-trusted scoped role, narrow PassRole grant, and hosting approval. Do not change participant trust, weaken MFA or expose an unauthenticated server.

After that gate is satisfied, confirm cfcaade is still the agreed integration revision, upload this exact ZIP, deploy the reviewed template/parameters, compare the resulting Lambda CodeSha256 with the value above, record the real HTTPS URL and test it with Cognito. If the native task supplies a newer functional commit, rebuild and revalidate instead of silently overwriting it with this package.

This packaging task performed no S3 upload, CloudFormation stack mutation, IAM change, Lambda creation or public exposure. The native task separately established the authorized temporary Cloudflare fallback at https://resumes-investigated-striking-mba.trycloudflare.com. Read-only health, authenticated existing-request/history reads and valid-other-user isolation checks passed at 2026-10-24T07:34:00.865883+00:00. Its public-URL Swift HTTP text/audio/replay flow subsequently passed, with this AWS task independently verifying the DynamoDB results/history, completed Transcribe job, S3 artifacts and empty queue at 07:44 UTC. Native PKCE/MFA, microphone/picker and phone UI remain untested. This fallback does not deploy the Lambda package; no artifact or shared runtime configuration was changed by the AWS verification.

Build-9 integration/evidence commit `8c207e736d269b02d52d888b8de12ac360ed1db7` has the same 11 backend modules as cfcaade. The ZIP/hash above remains unchanged. See CLOUD_DEPLOYMENT_HANDOFF.md and `cloud/docs/evidence/public-https-flow-readback-20261024.json` for the timestamped live results and safe request IDs.
