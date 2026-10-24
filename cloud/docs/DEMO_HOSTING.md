# Demo hosting — 24 October 2026

The current HTTPS API is **https://relay.stepcheck.app**. It uses:

Namecheap DNS → AWS CloudFront → HTTPS Cloudflare Quick Tunnel → this Mac's API
on loopback port8788 → Cognito, DynamoDB, S3, Transcribe and Bedrock as needed.
The worker on the same Mac processes queued batch speech and AI requests.

CloudFront distribution `E35672O7SGUTD2` uses CachingDisabled and
AllViewerExceptHostHeader. Authorization and WebSocket headers reach the API;
the origin Host remains the Quick Tunnel hostname. API responses are no-store.
Two enrolled roles returned the correct account on repeated requests, anonymous
access returned401, and native streaming passed over the custom domain.

Only two new DNS records were added: `relay` points to
`du685az67zetl.cloudfront.net`; the ACM validation CNAME proves control of that
subdomain. The existing apex/www website, mail records and nameservers were kept.
The ACM certificate is non-exportable and covers only `relay.stepcheck.app`.

This domain is a stable address, not an always-on compute service or an ASR speed
improvement. The Mac must remain powered, awake and connected to internet. If the
Quick Tunnel restarts with another random hostname, the distribution's origin
must be updated and deployed. The current tunnel should therefore stay running
through the rehearsal. The Mac was kept awake for eight hours starting around
03:19 PDT, not indefinitely.

An always-on PC is a reasonable later origin if its OS, network and authenticated
remote access are available. No such PC connection was configured here, so no
claim of PC deployment is made. Do not use unrelated research/HPC machines.
The dedicated Lambda role `relay-cloud-mvp-execution` still did not exist at the
last check. No IAM permissions were changed to bypass that blocker.

## Start / restart the API and worker

Use Python3.13 and install `cloud/requirements.lock` into a virtual environment.
Keep the AWS config, login cache, account memberships and credentials outside Git.
After validating the intended AWS account and a refreshed login, start:

```
PYTHONPATH=cloud python -m relay_backend serve --config /private/aws-config.json --port 8788
PYTHONPATH=cloud python -m relay_backend worker --config /private/aws-config.json
```

Bind the API only to loopback; expose it through the existing TLS tunnel.
Do not run a second listener on8788. Current private runtime config is documented
in the local work plan, not committed. Liveness `/v1/health` does not invoke AI
and cannot certify that the AWS login or worker is operational. Check an enrolled
`/v1/me`, worker progress, and a bounded synthetic workflow before presenting.

## Observed limits

Service Quotas reported standard Transcribe streaming concurrency25, stream starts
25/sec, and in-region Nova Lite2,000 requests/min and4M tokens/min in us-east-1.
These are account limits, not measured performance or guaranteed capacity.
The demo's own caps were raised from30 requests/5 transcription allocations to
100/20; counters were preserved. At the checkpoint they were20/7. Two direct
AWS streaming probes also ran outside those application counters. Four global
live sessions and one per account are enforced in the application.

Measured single synthetic sample:1.824s of audio, ready956ms, first partial2108ms,
durable complete3663ms through the custom hostname, including realtime pacing.
This is not a latency benchmark. Noisy/8kHz speech and repeated-failure reliability
have not been measured. The observed transcription still required correction of
“Shelter A,” which AWS recognized as “Sheltering.”
