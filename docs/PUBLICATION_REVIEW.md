# Publication review — October 26, 2026

## Scope

Reviewed the native Swift app/core, Python API/worker and tooling, test coverage,
configuration, repository history, evidence and setup documentation. Particular
attention went to framing and bounds, durable ACKs, encryption/receipt binding,
authentication/membership checks, request ownership, idempotency, inventory
transactions, profile sharing and speech resource limits. This is an engineering
review and regression run, not a formal security audit or a physical field test.

## Changes

- Brought the public main/dev content up to the latest native app/backend work.
- Removed hardcoded Cognito sign-in client/domain defaults. The app and CLI probes
  now use validated public deployment configuration; missing configuration fails
  before a sign-in request. Added four configuration tests.
- Removed the original Apple team and personal bundle ID from project defaults.
- Exposed a labeled nearby test lab from the signed-out screen without granting
  access to authenticated shelter accounts, inventory or resident data.
- Formatted Swift and Python sources. Python AST comparison found no semantic
  change outside the project generator. App builds caught and resolved one Swift
  multiline trailing-closure formatting issue.
- Added README architecture/feature/setup guidance, hackathon details, security
  boundaries, contribution instructions and CI. Marked hosted-demo docs historical.
- Strengthened ignore rules for private session/config/token files and runtime data.

## Publication hygiene

A private offline bundle preserves the original repository. All five existing
branch histories were sanitized before publication; the new dev branch shares the
reviewed main content. Personal home paths, private Gmail addresses, hardware
UDIDs, commit email addresses and old evidence screenshots were removed/replaced.
Authorship names and implementation history were retained. Commit hashes changed;
old clones should be replaced rather than merged back into the public tree.

Gitleaks found 14 historical matches, all verified SHA-256 source-file checksums.
The committed exceptions require both a narrowly matched evidence path and a
checksum-shaped source-file line. Subsequent tree and all-branch scans report zero
findings. A separate exact comparison against 30 locally held credential values
found no matches in 738 historical blobs or current files. No credential values
were printed or added to this repository. Known public AWS resource IDs in dated
evidence are identifiers, not access credentials.

GitHub may retain old commits through pull-request references or caches; rewriting
branches does not promise server-side erasure of those references. No actual
credentials were detected in the original branch-history scan either.

## Verification

| Check | Actual result |
| --- | --- |
| Swift unit/integration suite | 88 passed, zero failures |
| Python backend suite | 111 passed, one TestClient deprecation warning |
| macOS app build | Passed |
| iOS Simulator app build | Passed for arm64 and x86_64 |
| TCP control suite | Passed interruption, retries, duplicate suppression, restart, store/carry/forward and return receipt |
| Python correctness | Ruff checks passed |
| Formatting | Swift formatting and Ruff formatting applied and checked |
| Secrets | No findings after reviewed checksum exceptions; known-credential comparison clean |
| Hosted CI | [GitHub Actions run 1](https://github.com/NikilTn/relay/actions/runs/40359707144) passed for publication commit `ac35ad8` |

Tests used synthetic fixture data and same-host transport controls. No real AWS
calls were needed. Temporary TCP test processes exited. The original demo API,
worker, tunnel and native relay listener remain stopped; unrelated macOS/desktop
services were left intact. Existing cloud resources were not deleted.

## Remaining limitations

- Physical no-router three-device forwarding, reverse encounters, radio range and
  repeated-failure field reliability still require the documented acceptance plan.
- No production load, penetration, noisy-ASR accuracy, accessibility or security
  certification is implied by passing these tests.
- Legacy chat is plaintext; account-free lab controls are diagnostic only.
- Cloud setup is operator-provisioned. The old workshop deployment is not a public
  service, and managed Lambda hosting was not demonstrated.
- Existing app warnings identify deprecated Keychain interaction options and a
  non-Sendable capture in the serial-queue bridge. Strict Swift concurrency
  modernization and Keychain API migration should receive dedicated regression/UI
  tests; these warnings were not hidden with unchecked conformance.
- Supply handover records a staff action; neither the model nor a message receipt
  proves physical fulfillment. Offline replies/inventory sync, native Android
  radio integration, key lifecycle management and field hardening remain open.
