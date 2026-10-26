# Security and data boundaries

RELAY is a hackathon prototype, not an audited emergency-response service. Use
synthetic requests and recordings when reproducing the demo.

## Credentials and identity

AWS credentials remain server-side. Mobile clients hold short-lived Cognito access
tokens and refresh tokens in the system Keychain. A Cognito client ID, login domain,
public encryption key or AWS account number is an identifier, not a secret.
Server-configured membership controls resident/coordinator and shelter access.
A device name, UUID, Bonjour advertisement or test role does not establish identity.

The public app defaults to no cloud deployment. Configure your own public Cognito
client and HTTPS endpoint as described in the README. Use separate provisioned
accounts; sharing a login shares that account's permissions and request history.

## Nearby transport

Main shelter requests use ephemeral X25519 agreement, HKDF-SHA256 and ChaChaPoly.
A sender signature covers the exact request bytes. The backend verifies the
origin key against enrollment before accepting a carried request. Destination
receipts are signed with the receiver key pinned in the cached HTTPS directory.

Legacy nearby chat and diagnostic ACKs are unauthenticated plaintext. Transport
metadata is observable. This is not a production identity, anonymous messaging,
traffic-analysis resistance or adversarial mesh-security claim. A relay ACK does
not prove final destination delivery.

Device signing/encryption keys use a sandbox file with restrictive permissions
and iOS file protection. They are not Secure Enclave keys. Key rotation,
revocation, secure recovery, malicious-peer resource exhaustion and a third-party
cryptographic audit remain work to do. SQLite stores are not application-encrypted.

## Personal data and AI

Profile photos stay on the device. Profile fields are local/account-scoped; the
resident explicitly chooses whether to attach selected text to a request. Attached
fields become an immutable request snapshot and remain visible to authorized
shelter staff. Editing the profile cannot retract a previously sent snapshot.

Attached profile fields are excluded from the Bedrock extraction prompt. Text the
user types or dictates, including any sensitive information they put in that text,
is processed by the configured cloud services. Audio, location and transcripts
must therefore be treated as sensitive data. Retention/deletion policy and a
production consent/privacy review are not completed.

## Operations

The October 2026 Mac API, worker and tunnel were stopped on October 26. No demo
availability is promised. Shutting down local services does not delete AWS data
resources or revoke existing cloud sessions. Operators own cloud retention,
resource cleanup, costs and access revocation.

The local fixture API binds to loopback and uses generated test keys. Never expose
it publicly. The AWS mode requires a matching account guard and explicit write/AI
enablement. Do not weaken these checks to make a test pass. Legacy workshop setup
scripts and historical infrastructure files require review for your own account.

## Reporting a problem

Do not post credentials, personal data, recordings or token-bearing URLs in public
issues. Use GitHub's private vulnerability-reporting option if enabled, or contact
the repository maintainer through their GitHub profile for a private channel.
Provide a synthetic reproduction and identify the affected revision. This project
does not provide an emergency support service or response-time guarantee.
