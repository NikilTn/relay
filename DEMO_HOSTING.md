# RELAY temporary HTTPS demo

Current API: **https://resumes-investigated-striking-mba.trycloudflare.com**

Build 13 bundles this endpoint. It is an API, not a dispatcher website; use the
native requester or coordinator workspace. Follow [MOBILE_TEST.md](MOBILE_TEST.md)
for the prepared two-phone flow.

## What runs where

Phone/Mac RELAY → HTTPS Cloudflare tunnel → API on this Mac → actual AWS Cognito,
S3, Transcribe, Bedrock Nova Lite and DynamoDB. One worker on the Mac processes
AWS-backed durable jobs. Cloudflare transports HTTPS traffic; it does not host the
Python API or worker. The separate Apple nearby transport remains available.

The API binds to `127.0.0.1:8788`. The tunnel exposes only that port, never the
private login helper or local files. The old API on 8787 is stopped because its
old status routes lack the new inventory checks. Do not restart that old build.

The integrated API/worker include pre-send previews, optional structured location,
atomic inventory and durable retry handling. The API additionally uses bounded
batch reads for its inbox. It was restarted after the 67-test backend suite passed.
Public 19-item inbox snapshots returned in 0.449 and 0.478 seconds after that update;
these are isolated reads, not a load benchmark. Native Mac approval/release left
synthetic water stock at 20 on hand, 0 reserved, 20 available at 08:52 UTC.

## Keep the demo available

- Keep the Mac powered, awake, lid open and connected to internet. Keep the API,
  single worker and current tunnel running. AWS workshop credentials must stay valid.
- The current four-hour `caffeinate -i` session began around 00:20 PDT on October 24;
  extend it before a later presentation. The API process has no uptime guarantee.
- Keep phone internet on for the speech/AI/inventory test. The app prepares local
  drafts/outbox when offline, but AWS processing needs internet.
- The temporary tunnel hostname normally changes on restart. Keep this instance
  alive through the demonstration; do not start a second tunnel unnecessarily.
- At 08:52 UTC, shared bounds were 19/30 analysis slots and 4/5 audio allocations.
  One audio allocation remained. Reads and same-operation retries do not create
  new analysis. These are test caps, not dollar-spending measurements.
- A private owner-only helper at `127.0.0.1:8891` supplies existing synthetic app
  login details and expires automatically. It is not tunneled. Never expose it,
  commit its private inputs, or put its credentials in presentation material.

Lambda/API Gateway remains the preferred permanent target; the dedicated execution
role and scoped PassRole permission are still missing. See
[ORGANIZER_REQUEST.md](cloud/docs/ORGANIZER_REQUEST.md). A named tunnel can provide
a stable hostname when a domain/account is configured, but still needs a live host.

## Restart after a deliberate shutdown

Use the current integration checkout and the already-installed Python environment
containing `cloud/requirements.txt`. Keep AWS mode and Cognito authentication;
never expose fixture authentication. Substitute the private config path locally.

```sh
PYTHONPATH=cloud /path/to/venv/bin/python -m relay_backend serve \
  --config /private/runtime/aws-config-tunnel.private.json --port 8788
# Only if the existing worker has stopped:
PYTHONPATH=cloud /path/to/venv/bin/python -m relay_backend worker \
  --config /private/runtime/aws-config-tunnel.private.json
# Only if the existing tunnel has stopped; normally changes the hostname:
cloudflared tunnel --url http://127.0.0.1:8788 --no-autoupdate
caffeinate -i -t 14400
```

Check `/v1/health`, unauthenticated `/v1/me` rejection, then an authenticated profile
and inbox read. Health alone does not verify AWS access, model execution or worker
progress. Do not start duplicate workers. A new hostname requires a private config
copy's `public_base_url` and app endpoint update; account/endpoint-scoped old queues
are not automatically migrated.

When the demonstration is finished, stop the tunnel, then this API/helper and
keep-awake processes. Coordinate before stopping the worker. Stores persist;
shutdown does not erase messages or cloud records.

## Presentation wording

“Our API and worker run on this Mac behind HTTPS. Speech recognition, model
interpretation and durable cloud storage use real AWS services. Coordinators can
reserve and record stock handover. The Apple app also has a separate store-and-forward
text transport.”

Do not claim managed AWS hosting, autonomous dispatch, physical delivery verification,
an authenticated offline-to-cloud gateway, Android compatibility, or disaster
resilience. Cloud processing and controlled offline radio acceptance are distinct tests.
