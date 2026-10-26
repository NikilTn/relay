# RELAY at SpartHill Hacks 2026

## Event

- **Hackathon:** SpartHill Hacks 2026 — AI for Sustainable Impact.
- **Dates:** October 23–24, 2026.
- **Location:** Spartan Complex, San José State University, San José, California.
- **Hosts:** SJSU and Foothill College.
- **Project track:** AWS, as selected by the team.

[Official SJSU event listing](https://careercenter.sjsu.edu/events/2026/10/23/sparthill-hack-2026/)
· [Event schedule](https://sparthillhack2026.vercel.app/timeline)

## The problem we worked on

A resident needs water, food, shelter or medical support. Describing that need,
reaching a coordinator and knowing whether a request was received are different
problems. Connectivity can disappear before the request reaches its destination.
Coordinators also need to avoid promising the same supplies to several people.

RELAY combines a reviewed voice workflow, a staff-controlled stock ledger and a
persistent nearby delivery prototype. It is intended to explore community response
and resource coordination; no field impact, emergency-service certification or
hackathon award is claimed by this repository.

## What we built

Residents can speak or type, correct a proposed request, attach a location snapshot
or landmark, and send to an enrolled shelter. Amazon Transcribe produces the
transcript. Amazon Bedrock Nova Lite proposes structured fields; application
validation and human review determine what is sent.

Coordinators see requests, reply, reserve supplies, record handover and release
reservations. Amazon Cognito supplies account identity, DynamoDB stores shared
state, and S3 supports batch-audio retry. Models do not authorize allocation.

The Apple client shares a Swift/SQLite relay engine across iPhone and Mac.
Messages survive disconnection and restart. A carrier can forward an encrypted
shelter request during a later encounter, and a signed receipt can travel back.
The native transport uses Network.framework and Bonjour with peer-to-peer enabled.
Physical no-router, out-of-range delivery still needs documented acceptance tests.

## Thirty-second coordinator demo

Prepare a synthetic request in the inbox before recording.

> This is RELAY's shelter coordinator view. A resident's spoken request becomes
> structured information using Amazon Transcribe and Bedrock. I review the need
> and location, then reserve one water pack. Inventory updates, keeping available
> and reserved supplies separate. The resident can track the response, while the
> coordinator stays in control.

1. Open the request and show reviewed details.
2. Enter a quantity and choose **Approve and reserve**.
3. Open Inventory to show the reservation. On-hand stock changes only on handover.

The October 2026 Mac demo server is now stopped. Reproduce this workflow only with
your own authorized deployment or the clearly labeled local fixture backend.

## Demonstrating the relay honestly

Show separate A/B and B/C encounters, restart the carrier between them, then
return a destination receipt through B to A. Record message IDs and persistence
logs. If nearby A/C devices are blocked only by an app setting, call it a logical
relay test. Document radio/router isolation before making a physical wireless claim.
The detailed procedure is in [TEST_PLAN.md](TEST_PLAN.md).

## Team context

This is the native Apple app and Python backend repository maintained on NikilTn's
profile. The team's combined repository, including separate React/Expo work, is
[AdityaDave2008/RELAY-Sparthill2026](https://github.com/AdityaDave2008/RELAY-Sparthill2026).
The projects do not yet share one fully integrated cross-platform transport/API.
