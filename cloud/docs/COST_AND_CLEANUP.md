# Cost observations and cleanup

**Current consumption:** zero Bedrock inference calls, zero Transcribe jobs, no hosted stack, and no new AWS resource provisioning from this milestone. Read-only account/resource checks and official CLI authentication succeeded. Actual billing/credits have not been reconciled; do not report an inferred $0 invoice. The proposed incremental test allowance is $2, pending explicit approval. The earlier $5 planning number was not approval.

The initial live test uses four text analyses (ordinary, missing quantity, negation and reviewed transcript) plus one short synthetic/TTS audio job. Additional checks may run only within 30 accepted requests and five recordings. Each request has a maximum of three automatic model dispatches per cycle and two explicit retry cycles; the counter is durable before each model dispatch, including crash recovery. Output is capped at 512 tokens. A process failure after a response can still create another billable invocation within these limits. Transcription polling is bounded, and job names are deterministic.

Record Bedrock input/output token usage and request IDs from safe API results; record Transcribe job name and actual recording duration. Separate usage-derived cost estimates from delayed account billing. Do not infer workshop credits from access alone. No TTS, streaming, GPU instance, training or model subscription is part of this scope. Hosted recovery schedules have continuing idle costs and require separate approval.

## Cleanup review

Nothing cloud-side has been created yet; `RESOURCE_MANIFEST.json` states that explicitly. After provisioning, preserve the private runtime `created-resources.json`, and copy only non-secret IDs and test resource references into the repository manifest. Never copy `demo-identities.private.json`, tokens, passwords, TOTP secrets, browser login caches or presigned forms.

When cleanup is requested:

1. Stop the task's API/worker processes. If hosted later, disable recovery invocations and delete only the recorded `relay-cloud-mvp` stack. Confirm the stack owns each resource before deletion. The existing table/pool/bucket and organizer-managed role are outside that stack.
2. Delete only manifest-listed `relay-mvp-{transcription UUID}` jobs and their exact upload/sealed/transcript object keys. For deployment artifacts, delete only recorded object keys. Do not empty or delete the bucket or alter its policies.
3. Remove only manifest-owned synthetic request/transcription records, owner/shelter index references, operation records, work entries and counters in the `RELAY_MVP_V1#` namespace. Do not scan/delete the entire table or delete anything outside that prefix. Inspect pending work and export needed evidence first. If the namespace has acquired another producer, reconcile ownership instead of deleting the whole namespace.
4. Delete only the four synthetic users, newly created public client and newly created domain whose IDs match the runtime manifest. Never delete the existing user pool, original web client, dispatcher group or actual users. Confirm no app still depends on the new client/domain before deleting them.
5. Log out the task-specific CLI session and remove only task-owned temporary credential/token/TOTP files when no longer needed. Keep source, PR and sanitized test evidence. Never delete the user's unrelated AWS profiles or credentials.

No automatic cleanup or retention timer is enabled. These instructions describe a reviewable future cleanup; no destructive action has been performed.
