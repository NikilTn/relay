# RELAY test results — updated 2026-10-24

**Verdict: implemented and tested as a software prototype; the controlled physical offline demonstration remains pending and unverified.** No physical wireless acceptance test is reported as a pass. Software evidence below does not establish disaster resilience.

## Current release — 0.1.0 (13), 2026-10-24

**Implemented and ready for the operator's two-phone cloud test.** Public Help / Requests / Messages and coordinator Inbox / Inventory / Messages now use server-authorized roles. The workflow covers voice upload/transcription, editable AI preview before Send, optional one-shot location or landmark, durable drafts/outbox, coordinator reservation/handover/release, inventory and request history. See [MOBILE_TEST.md](MOBILE_TEST.md).

| Verification | Actual result |
|---|---|
| Shared Swift tests | **PASS: 49, 0 failures**, [log](evidence/build13/swift-tests.txt) |
| Backend tests | **PASS: 67**, including transaction races, durable retries, preview reuse, inventory and bounded batch reads, [log](evidence/build13/backend-tests.txt) |
| Separate-process TCP control | **PASS**, including interrupted frame and relay process restart; loopback only, [log](evidence/build13/tcp-control.txt) |
| Build 13 native Mac / signed iOS / release archive | **PASS**, [markers](evidence/build13/build-markers.txt) |
| Physical 15 Pro Max / iPhone 16 install and launch | **PASS**; each retained all 32 prior messages, identity, shelters and final-receipt state. [15 Pro Max](evidence/build13/iphone15promax-install.json), [16](evidence/build13/iphone16-install.json) |
| Native Mac password + MFA, Bedrock preview, Review/Send | **PASS** against public HTTPS and actual AWS; request `c24d0173-8d0a-41bf-81f4-63a887d243bc`, [independent readback](evidence/build13/native-mac-ui-request-readback.json) |
| Native Mac coordinator approve / inventory / release | **PASS**: 20 on hand → 2 reserved / 18 available → release restores 20 available; [independent ledger readback](evidence/build13/native-mac-ui-release-readback.json) |
| Swift live HTTP preview/location/fulfillment/retry | **PASS** with synthetic location 0,0; request `cf8bf57d-2058-4c4c-87c7-46bde6149a7e`. Reserve/fulfill replays did not duplicate stock movement; synthetic consumption restored. [Live evidence](evidence/build13/swift-live-flow.json) |
| Fixture audio→preview→location→send→inventory | **PASS**, simulated providers; [separate fixture evidence](evidence/build13/swift-fixture-flow.json) |
| Build 13 TestFlight | Upload **PASS** at 01:47 PDT; Apple showed **Testing** in internal RELAY Development group, 1 tester. What to Test saved. External build submission remains blocked behind the already submitted beta review. |
| Phone microphone, real GPS, full phone tap sequence | **NOT TESTED by agent**; operator test now required. Native WAV picker correction compiled, post-fix picker UI not reverified. |
| Controlled physical no-internet/no-router tests A–E | **NOT TESTED**; user reports nearby messaging worked, but no controlled network-state evidence was captured. |

Current physical devices: iPhone 15 Pro Max, iOS **27.0.1 (24A446)**; iPhone 16, iOS **26.2 (23C55)**. Host remains M3 Pro / macOS 26.6.2, Xcode 26.1.1 / iOS and macOS 26.1 SDKs. Original phone bundle `org.relay.prototype.ios` was signed using development team 3TUBL56UTY; release bundle `com.nikilthalapaneni.relay` used enrolled team U4G9LV39GM. No data migration between these separate installations is claimed.

The owned debug phones were prepared as Requester-A (15 Pro Max) and Dispatcher-A (16) using existing MFA-authenticated sessions verified against `/v1/me`. One-use files were consumed and deleted, and both cached authorized shelter directories. The importer is DEBUG-only; the release binary was checked to exclude its filename. Normal native password/MFA sign-in was separately exercised on Mac; long-duration native Keychain refresh and account-switch race handling need further verification.

The current API and worker run on this Mac with actual Cognito, DynamoDB, S3, Transcribe and Bedrock Nova Lite. Internet remained available. Public inbox reads after the bounded batch-read update returned 19 items in **0.449 s and 0.478 s**, versus an earlier single **7.77 s** observation. These are three individual snapshots, not a load benchmark or wireless metric. [Read evidence](evidence/build13/public-inbox-read.json). The API was restarted alone; no parallel old worker or old API remains.

Native preview `c725d1b2-efd8-4385-85cc-e11de4c2767d` used real Bedrock, then was reused when sent without a second analysis. Native coordinator reserve operation `2115b0f0-4e5a-4275-95f8-daf4480e4804` and release `e151dd25-933e-48d5-97ab-2d9655d39e5f` each appear once in the ledger. Final synthetic water stock at 08:52 UTC was on_hand=20, reserved=0, available=20, revision=6. No physical handover was claimed. Counters then showed **19/30 analysis slots and 4/5 audio allocations**; one audio allocation remained. New tests may change these values.

Remaining boundaries: the cloud composer waits for its origin device to regain internet; authenticated carrier-to-cloud ingestion and encrypted location/reply relay are pending. The existing P2P engine remains plaintext and foreground-only. The Mac must remain online/awake for cloud hosting; permanent AWS deployment still needs the organizer role. No measured radio range, noisy-ASR quality, physical resilience, background mesh or autonomous dispatch claim is made.

## Historical initial environment and access

The table below records the first session before physical phones and signing were available. It is superseded by the current release results above.


| Item | Observed result |
|---|---|
| Development hardware / available physical C | Apple M3 Pro, model Mac15,6, arm64 |
| Host OS | macOS 26.6.2, build 25G83 |
| Xcode | 26.1.1, build 17B100 |
| Swift | Apple Swift 6.2.1, swiftlang-6.2.1.4.8 |
| SDKs used | iOS 26.1, iOS Simulator 26.1, macOS 26.1 |
| Simulator UI test | iPhone 17 Pro simulator, iOS 26.1; **not a physical iPhone** |
| Physical iPhones A and B | Unavailable to this session: `xcrun devicectl list devices --timeout 10` returned `No devices found.` |
| Development signing identities | `security find-identity -v -p codesigning`: `0 valid identities found` |
| iOS device signing | **BLOCKED**: actual signed-build attempt failed: `Signing for "RELAY-iOS" requires a development team.` No profile/install on a phone was completed. |
| macOS signing | **PASS for local ad hoc signing**; `codesign --verify --deep --strict` reports valid on disk/designated requirement; sandbox client/server entitlements present. This is not Developer ID/notarization or iOS provisioning. |
| Operator network conditions | Physical isolation was **not performed**. Host network/radio settings were left unchanged. No internet-off or no-router certification was made. |

Evidence: [environment](evidence/environment.txt), [devices](evidence/devices.txt), [identities](evidence/signing-identities.txt), [actual iOS signing failure](evidence/signing-ios.txt), [Mac signing verification](evidence/signing-macos.txt).

## Builds and automated verification

| Check | Result | Actual evidence |
|---|---|---|
| Shared Swift package + RelayLab | PASS | [build-core.txt](evidence/build-core.txt) |
| Native macOS arm64 Debug app | PASS, ad hoc signed and launched | [build-macos.txt](evidence/build-macos.txt), [native events](evidence/native-mac-events.txt) |
| iOS Simulator Debug app | PASS, installed and launched | [build-ios-simulator.txt](evidence/build-ios-simulator.txt), [launch record](evidence/simulator-launch.txt) |
| iOS arm64 device SDK build | PASS **unsigned only** | [build-ios-device-unsigned.txt](evidence/build-ios-device-unsigned.txt) |
| Unit/integration tests | PASS: **17 tests, 0 failures** | [automated-tests.txt](evidence/automated-tests.txt) |
| Real TCP separate-process control | PASS, including actual SIGKILL/restart of B | [tcp-control.txt](evidence/tcp-control.txt) |
| Native Mac ↔ iOS Simulator Bonjour/UI control | PASS for discovery, request, receipt, storage | [Mac log](evidence/native-mac-events.txt), [simulator log](evidence/ios-simulator-events.txt) |
| Existing parent-repo tests | PASS: 30 tests, 1 expected skip | [repo-regression.txt](evidence/repo-regression.txt) |

Initial Mac build issues were corrected: Debug architecture settings were aligned with the package; code signing rejected Finder/file-provider metadata on the generated `.app` under Documents, so final Mac DerivedData was moved to `/tmp/RELAY-mac-build`. No source permissions/security protections were weakened. The iPad orientation plist warning was corrected. Xcode may emit its informational App Intents metadata-extraction warning because this app does not use that framework.

The 17 tests cover JSON roundtrip and field names, framing at every byte split and coalesced frames, malformed/version rejection, SQLite restart identity/message/ACK recovery, duplicate/UUID collision handling, expiry and final-hop boundaries, shorter duplicate routes, inventory filtering, same-link and reconnected lost-ACK retries, A→B→C and receipt return across store reopen, wrong claimed receipt origin, logical route blocking, unsolicited ACKs, durable receipt state after sender restart, and atomic rollback/no ACK when capacity cannot accommodate request plus receipt.

**Repeated-failure measurement is simulated only:** one test deliberately drops a partial frame in **30 consecutive encounters**, asserts no receiver insert/false delivery, then succeeds on attempt 31 with one logical message. Another repeats the same destination message 20 times and verifies only one generated receipt. These are deterministic assertions, not physical failure-rate/range/latency estimates.

## Real TCP control evidence (three processes on one Mac)

Final captured run: **2026-10-23 22:35:31–22:35:32 UTC**. All connections used explicit `127.0.0.1`; logs report `interfaces=[lo0:loopback]`, `wifi=false`, `cellular=false`. Bonjour was disabled for this experiment. Host internet status was irrelevant to loopback and not certified as disabled.

| Node/message | Actual UUID |
|---|---|
| A process | `635061e7-3845-4110-acd4-3d9fbf5f520a` |
| B process | `d06b3b81-20b1-4c5b-bc3e-31046c8e02c0` |
| C process | `f5085f41-4550-477c-9d05-e28add22c52a` |
| Original request M001 | `ea3b96c5-e750-4dcb-b18e-9f14f5add88b` |
| Destination receipt | `e775e3de-1e17-4c9f-8e16-93ef17a302e7` |

The [reproducible harness](scripts/tcp_experiment.py) verified:

1. A's deliberate half-frame send was discarded. B had no M row; A had neither an ACK nor final receipt.
2. A reconnected to B; B persisted M at hop 1. Duplicate transmission left one row at B.
3. A stopped networking. **B was killed with SIGKILL** after its committed ACK, then relaunched against the same SQLite WAL store. Identity and M survived.
4. B connected separately to C, which persisted the original at hop 2 and generated a separate receipt. B persisted the receipt. Repeating M to C left one request and one receipt.
5. C stopped networking. B's process was terminated/restarted again, then connected to A. A persisted the receipt at hop 2 and recognized it as final destination delivery.

Selected actual output (full timestamps, session IDs, paths, attempts, and final snapshots are in the raw log):

```text
2026-10-23T22:35:31.778345+00:00 PASS control interruption: no destination insert or false ACK
2026-10-23T22:35:31.991722+00:00 B deliberate SIGKILL after durable acceptance
2026-10-23T22:35:32.028058+00:00 PASS actual B SIGKILL/restart: same device ID and message recovered from SQLite WAL
2026-10-23T22:35:32.246664+00:00 PASS separate B->C encounter; one request, one receipt; A disconnected
2026-10-23T22:35:32Z [635061e7-3845-4110-acd4-3d9fbf5f520a] FINAL_RECEIPT_RECOGNIZED id=e775e3de-1e17-4c9f-8e16-93ef17a302e7 original=ea3b96c5-e750-4dcb-b18e-9f14f5add88b
2026-10-23T22:35:32.500063+00:00 PASS C->B->A receipt across second actual B process restart
```

The host processes are not three physical devices. This proves application/protocol/persistence behavior over the actual TCP adapter, not local-radio compatibility or infrastructure independence. These short control timings are not a performance benchmark.

## Native UI and Bonjour control evidence

Native Mac device UUID: `fabb432e-244d-4be8-86eb-eb9ac6982d0f`. iOS Simulator UUID: `989a39ee-67c7-4cfe-bd50-67d44e31c0ce`.

- The Mac UI saved request `17813539-3e39-4d6d-b524-be26a3c81115` at 22:28:40 UTC. After stopping networking, quitting, and relaunching at 22:28:53 UTC, the same UUID/message was visibly retained. It was still queued with no final receipt.
- Both apps started Bonjour. Mac discovery at 22:29:31 UTC listed the simulator, and the connection became ready at 22:29:32 UTC. Timestamps have second-level precision; no controlled discovery-latency measurement was made.
- Discovery included `awdl0`, **but the actual connection log showed `interfaces=[en0:wifi,lo0:loopback]` with both endpoints on `10.251.234.66`** (same host). This is expressly not evidence of an AWDL wireless data path or two physical radios.
- The Mac UI sent synthetic request `68027e07-97de-41c7-8e3b-0db0ebaadb83` to the simulator. At 22:29:43 UTC the Mac logged a destination storage ACK with **one observed 9 ms ACK interval**, followed by recognition of separate receipt `e5cf530b-1a29-4004-9d2f-85732363d62b`. This is one same-host control observation, not a wireless latency estimate.
- Both apps showed the distinct receipt state. Networking was then stopped on both apps. After installing/relaunching the latest simulator build, the simulator still displayed the original message and receipt; its role selector was exercised successfully. The [actual simulator screenshot](evidence/ios-simulator.png) shows stored synthetic data and receipt status. It is labeled simulator evidence only.
- No physical-device Local Network prompt was tested. Mac/simulator listener/browser reached ready with available local access; the session did not require an interactive permission approval. This does not establish physical iOS permission behavior.

Read-only storage exports: [native Mac messages](evidence/native-mac-stored-messages.json), [simulator messages](evidence/ios-simulator-stored-messages.json). Raw logs and synthetic snapshots are retained; no private keys, passwords, or provisioning profiles are included. The source/config hashes in [source-sha256.txt](evidence/source-sha256.txt) identify the delivered implementation.

## Mandatory physical acceptance results

| Test | Physical result | Network state / reason |
|---|---|---|
| A — direct offline iPhone A→B | **NOT TESTED** | Both phones are now installed/launched; no physical no-internet/no-AP delivery result or logs have been captured. |
| B — A→B→C, B restart | **NOT TESTED** | Protocol behavior passes in simulated/TCP controls; no three-device radio encounters. |
| B variant — A/C genuinely out of range | **NOT TESTED** | No physical separation or range experiment. Logical route enforcement is implemented/tested only. |
| C — physical C→B→A receipt | **NOT TESTED** | Return receipt passes in software controls only. |
| D — duplicate physical delivery | **NOT TESTED** | Duplicate suppression passes simulated/TCP controls; no physical repeated transmissions. |
| E — unexpected physical disconnection | **NOT TESTED** | Partial TCP frame and process failure controls pass; no range/radio disruption trials. |

No physical message IDs, radio discovery times, transfer latency distribution, packet captures, or success rate exist for A–E. The UUIDs above belong to software controls and must not be repurposed as hardware evidence.

## Separate claim verdicts and next gates

| Claim | Verdict |
|---|---|
| 1. Direct offline P2P communication verified | **NO — physical verification blocked** |
| 2. Three-device store-and-forward verified | **NO on physical devices**; software engine plus three separate TCP processes verified |
| 3. Bidirectional delivery verified | **NO on physical devices**; request and return receipt verified in controls |
| 4. Infrastructure-independent wireless path verified | **NO**; peer-to-peer opt-in is configured, path independence remains unverified |
| 5. Reliability under repeated failures measured | **SIMULATED ONLY**: 30 interrupted encounters then successful retry; physical reliability not measured |

Next: execute [TEST_PLAN.md](TEST_PLAN.md) A→E on the installed physical phones and Mac with exported evidence. No password needs to be sent to this agent. Verify OS permission behavior and actual no-AP conditions, repeat with A/C out of range, then collect physical failure/latency/energy/range statistics. Long carries, device reboot/power loss, quotas, clock drift, background suspension, congestion and adversarial peers remain untested. Plaintext/unauthenticated security, foreground-only behavior and encounter dependence rule out a production disaster-resilience claim.


## Physical-test setup follow-up — 2026-10-23

The user subsequently connected a physical iPhone 15 Pro Max, running iOS 27.0.1 (24A446), over USB. The earlier no-device observation above remains the record of the initial implementation session. Current probe: paired, Developer Mode disabled, developer disk services unavailable. Xcode has a signed-in Personal Team with no provisioned devices; an automatic-signing build failed because no registered device/profile was available. Mac RELAY is prepared as Receiver C with networking stopped. The second iPhone has not yet been observed. Physical A–E and wireless path verification remain NOT TESTED. See [setup probe](evidence/physical-setup-20261023.txt).

An explicit build targeting the connected physical phone subsequently confirmed the immediate blocker: `Developer Mode disabled`. No Xcode/iOS software update has been established as necessary by that attempt. The user reports slow internet; no large update was initiated.


## First physical installation follow-up — 2026-10-23

Developer Mode was enabled on the iPhone 15 Pro Max (iOS 27.0.1), and developer disk services became available. The existing Xcode 26.1.1 / iOS 26.1 SDK successfully built and development-signed RELAY using the signed-in Personal Team. Automatic provisioning and USB installation of `org.relay.prototype.ios` succeeded. No software update was needed for these steps. Local signature verification passed, signing-input entitlements match the provisioning profile, and the connected phone is included. The profile expires **2026-10-30 22:50:54 UTC**.

The first launch was denied with the iOS Security message covering invalid signature, inadequate entitlements, or a developer profile not explicitly trusted by the user. Given the successful local checks, developer-profile trust is the next on-phone step; launch success is not yet claimed. The second phone is not installed yet. **Physical tests A–E and infrastructure independence remain NOT TESTED.** Sanitized evidence: [first-phone installation](evidence/physical-install-first-phone.json).

**Launch retry succeeded:** after the user completed the on-phone trust step, `devicectl` launched RELAY at 2026-10-23 22:54:12 UTC. The physical app container contains SQLite/WAL/SHM and an `APP_OPEN` record, with persistent UUID `d8024643-427c-43dd-a991-7db89543bf19` and zero messages. See [physical launch evidence](evidence/physical-first-phone-launch.txt). This confirms installation/launch/storage initialization on one actual iPhone, not wireless delivery. The second phone and physical A–E tests remain pending.


## Second phone setup and distribution assets — 2026-10-23

An iPhone 16 (iPhone17,3) running iOS 26.2 (23C55) is now detected over USB and paired. Its Developer Mode remains disabled; installation is pending the user enabling it. [Second-phone probe](evidence/physical-second-phone-setup.json). Physical A–E tests remain NOT TESTED.

Added opaque app-icon assets for iOS/macOS and deterministic generation. Both [iOS device build](evidence/build-appicon-ios.txt) and [macOS build](evidence/build-appicon-macos.txt) pass with the icon. Core engine and protocol sources were unchanged, so earlier 17-test evidence remains applicable; tests were not rerun solely for icons. Current setup source hashes: [source-sha256-physical-setup.txt](evidence/source-sha256-physical-setup.txt). [TestFlight preparation](TESTFLIGHT.md) includes beta metadata drafts; no distribution upload or review submission has occurred.

**Second-phone installation succeeded:** Developer Mode and DDI services were enabled, and the signed build installed on the physical iPhone 16. The first iPhone was updated with the same build over its existing paired local-network connection. Both devices are included in the provisioning profile (expires 2026-10-31 00:50:21 UTC). This setup network use is not an offline transmission test. Initial launch on the second phone hit the generic iOS signing/trust Security denial; local signature checks passed and user profile trust is pending. [Installation evidence](evidence/physical-second-phone-install.json). Physical A–E remain NOT TESTED.

**Second-phone launch succeeded after trust:** `devicectl` confirmed launch on iPhone 16 at 2026-10-24 00:53:28 UTC. Verified persistent UUID `4e328dc5-51a9-4e37-92d6-833a81c32078`, a startup log, and an empty message store. [Launch evidence](evidence/physical-second-phone-launch.txt), [startup events](evidence/physical-second-phone-startup-events.txt), [physical peer map](evidence/physical-peer-map.json). Mac RELAY UI was confirmed stopped. The operator is setting up an unplugged, cellular-off/no-AP phone-to-phone discovery test; connection and delivery outcomes are pending.

## Keyboard fix and TestFlight account setup — 2026-10-23 PDT

Version **0.1.0 (2)** adds explicit focus state and a navigation Done button, interactive scroll dismissal, and focus clearing on destination selection/send. In the iPhone 17 Pro / iOS 26.1 simulator, software keyboards for both destination and multiline message fields disappeared after tapping navigation Done, with text preserved. [Observed UI checks](evidence/keyboard-ui-check.txt), [actual post-dismissal simulator screenshot](evidence/keyboard-dismissed-simulator.png). The keyboard accessory toolbar did not expose its own Done control in this simulator, so the navigation Done button is the verified path.

[Simulator build](evidence/build-keyboard-ios-simulator.txt), [macOS build](evidence/build-keyboard-macos.txt), and [unsigned iOS Release archive](evidence/archive-keyboard-ios-unsigned.txt) all **PASS**. The final archive's plist confirms version 0.1.0, build 2, and `ITSAppUsesNonExemptEncryption=false`; source review found no application encryption or third-party crypto. These are local compile/UI results, not App Store validation or physical keyboard verification. Shared engine sources were unchanged; the earlier 17-test results remain applicable and were not rerun solely for this UI/metadata change. [Current source/config hashes](evidence/source-sha256-keyboard-testflight.txt).

User completed App Store Connect sign-in for the enrolled developer account. Verified paid team **U4G9LV39GM**; App Store Connect lists no apps. New App opens an **Agreement Update** blocker. Apple Developer account states the updated Program License Agreement must be accepted to regain membership resources. User was asked to review/accept directly in Apple's page. No agreement accepted by agent, app record created, distribution signing completed, build uploaded, beta review submitted, or TestFlight link created. Physical phones still contain the earlier development build. Publication continuation and repeatable upload script: [TESTFLIGHT.md](TESTFLIGHT.md).

## TestFlight upload and review submission — 2026-10-23 PDT

The user accepted Apple's updated agreement. Registered `com.nikilthalapaneni.relay` under enrolled team U4G9LV39GM after Apple rejected the original Personal Team identifier as unavailable. Created **RELAY Offline Lab**, App Store Connect ID **6826458231**. Registered the previously verified Sender A device for the new team's initial development profile; this resolved the first archive attempt's no-registered-devices error without reconnecting a phone.

Signed release archive **PASS**, local signature verification **PASS**, App Store Connect export/upload **PASS** at **18:18:46 PDT**. Apple processed version **0.1.0 (2)** and exposed it as Ready to Submit. Created internal group RELAY Development and external group RELAY Teammates; submitted the latter's build with test instructions and user-approved review contacts. Verified the build row now reads **Waiting for Review**. No Apple review approval or TestFlight phone installation is claimed.

Public invitation created: **https://testflight.apple.com/join/paGggTvE**, open to anyone with the link, limit 100. Apple's group page explicitly states: `Testers cannot join public link until this group has an approved build.` Automatic tester notification is selected for the submitted build. No individual teammate invitations or App Store Connect account access were granted.

Evidence: [signed archive log](evidence/archive-testflight-build-2.txt), [actual upload output](evidence/testflight-upload-build-2.txt), [sanitized build/review/link record](evidence/testflight-upload-build-2.json), [source/config hashes](evidence/source-sha256-testflight-build-2.txt). The generated iOS project now defaults to the enrolled team/identifier; the archive used those same effective settings via command-line overrides. Private contact details, credentials, provisioning profiles and signing keys are not included in this release record. No core protocol code changed or additional wireless acceptance evidence was collected. Physical claims 1–4 remain unverified; repeated-failure measurements remain software-only.


### Immediate internal-testing availability

After the user reported a tight deadline, added the existing account holder to RELAY Development without adding account roles. Verified App Store Connect **1 Tester**, **Invited**, and internal build **0.1.0 (2): Ready to Test**. The external submission remains pending; its public invitation gate is separate. User still needs to accept the internal invitation/install through TestFlight. No inbox delivery, physical installation of build 2, or offline transfer is claimed. Device probe at this point sees iPhone 15 Pro Max available/paired and iPhone 16 unavailable.


## Usability refresh / build 3 — 2026-10-23 PDT

User requested a usable, attractive app for immediate testing on two phones. Replaced the engineering form with Messages, Nearby, and Tools; navy connection cards and adaptive light/dark accents; a validated compose sheet with known-peer/manual destinations, synthetic templates and reliable Done controls; message filters and detail progress; Reply for incoming requests; copy/share identity; and retained path/log/duplicate/interruption diagnostics. New stores default to unrestricted nearby connections; existing saved role/forced-route settings are preserved. Changing setup reconnects only if networking was already active. Saves dismiss the composer only after durable success; unsaved drafts are memory-only. No wire protocol/database schema change, cloud, AI, or new transport was introduced.

| Build 3 check | Actual result |
|---|---|
| iOS simulator / iOS development-signed / macOS builds | **PASS**; final source compiled for all three |
| Paid-team release archive and App Store Connect upload | **PASS**; uploaded 18:52:36 PDT; processed; internal group shows **Testing** |
| XCTest unit/integration suite | **17 tests, 0 failures** |
| Three-process actual TCP / SIGKILL / duplicate / retry / return receipt control | **PASS**; loopback only |
| Simulator invalid destination validation | **PASS**; invalid UUID disables Save & send and shows guidance |
| Keyboard dismissal | **PASS in simulator**; in-message Done removed software keyboard and retained text; navigation Done also present |
| Queued UI request after app terminate/relaunch | **PASS**; same synthetic request retained and still queued before connection |
| New UI request, reply and both final receipts | **PASS Mac↔iOS Simulator control**, not a physical wireless test |
| Mac UI navigation / retained old messages / light and dark presentation | **PASS** for observed controls and visual inspection |
| iPhone 15 Pro Max direct update / launch | **PASS**; 0.1.0 (3), same UUID `d8024643-427c-43dd-a991-7db89543bf19`; empty store before and after, no data reset |
| iPhone 16 build 3 update | **PASS** after it became reachable; installed and launched at 18:58:01 PDT; UUID/store preserved |
| Physical no-internet/no-router delivery | **NOT TESTED**; no physical radio/path claim |

The new same-host UI request ID is `01a93319-01a6-42b1-a666-bc42c13b7784`, simulator origin `e816be05-b366-4b44-a5dd-8b56ef7e5884`, Mac destination `fabb432e-244d-4be8-86eb-eb9ac6982d0f`, final receipt `ecb318f9-bd7b-478c-a1a9-61a6a0f85b8b`. The simulator first saved it with networking paused; process terminate/relaunch retained it. After discovery, Mac persisted it and returned a separate receipt. The Mac Reply action prefilled the simulator address and sent a synthetic reply, which also obtained a final receipt. Both stores were checked. Mac and simulator networking were paused afterward for the physical phone test. Final presentation refinements changed sorting/colors only; final builds and visual checks passed afterward.

Evidence: [17 tests](evidence/automated-tests-build-3.txt), [TCP control](evidence/tcp-control-build-3.txt), [UI request/reply record](evidence/ui-build3-control.json), [Mac events](evidence/ui-build3-mac-events.txt), [simulator events](evidence/ui-build3-simulator-events.txt), [actual final simulator screenshot](evidence/ui-build3-final-simulator.png), [queued screenshot](evidence/ui-build3-messages-simulator.png), [physical install record](evidence/physical-build3-install.json), [physical launch](evidence/physical-build3-a-launch.txt), [release record](evidence/testflight-upload-build-3.json), [upload output](evidence/testflight-upload-build-3.txt), [source hashes](evidence/source-sha256-ui-build3.txt).

Both physical installations are now complete. Required next physical steps: execute Test A with both phones unplugged and documented radio isolation. In Tools, turn off Force A → B → C on both for the direct test; start connections; choose the other phone in Nearby; send synthetic data and capture the actual request/receipt logs. Follow B–E afterward; the five final claim verdicts remain unchanged until those physical results exist.


**Second phone update completed:** iPhone 16 became reachable after the earlier unavailable probes. Backed up its existing store, installed and launched version 0.1.0 (3), and confirmed UUID `4e328dc5-51a9-4e37-92d6-833a81c32078` and all pre-existing message IDs survived. The store was empty before and after this update. Both phones now run the redesigned build under their original identifiers. [Second-phone install](evidence/physical-build3-b-install.txt), [launch](evidence/physical-build3-b-launch.txt), [combined verification](evidence/physical-build3-install.json). This is installation evidence, not offline wireless success.


## Build 4 — chat UI and repeat-send fix, 2026-10-23 PDT

User reported no accessible new-message action after sending and requested a normal chat UI with appropriate sizing. Build 4 replaces the modal send-and-dismiss flow with peer conversations and a fixed bottom composer. Saving clears text only after success and retains the current conversation/focus; the input is not disabled during the asynchronous save, and newly typed text is preserved if it differs from the submitted snapshot. The chat list has an unconditional, labeled New chat control. Bubbles use body-sized text, width limits, timestamps, and separate queued / relay-saved / destination-saved / final-receipt states. New chat can open known or manually addressed peers. Relay traffic and receipt envelopes remain in Tools → Open durable queue.

Added `Conversations.swift`, a presentation-only projection, and four regression tests covering incoming/outgoing grouping, carried-traffic exclusion, receipt-envelope suppression with retained delivery state, and separate-peer/latest-chat ordering. Wire protocol, networking and durable schema are unchanged. **21 tests pass** (17 existing plus 4 new). Final iOS Simulator, signed iOS, macOS and paid-team release archive builds pass.

Observed simulator UI regression: sent `SYNTHETIC CHAT-004: First consecutive message.` with the software keyboard visible; the conversation, keyboard and empty composer remained. Typed and sent `SYNTHETIC CHAT-004: Second message, same chat.` without reopening a composer. Done dismissed editing. Both messages survived process terminate/relaunch. New chat remained available and selected the existing peer's thread; no duplicate thread/bubble was created. macOS chat/back navigation also returned to the persistent New chat control. These are software UI tests, not physical radio tests. [Repeat-send record](evidence/ui-build4-repeat-send.json), [actual simulator chat screenshot](evidence/ui-build4-chat-simulator.png), [21-test output](evidence/automated-tests-build-4.txt).

Physical deployment: both iPhones successfully installed and launched build 4 at **19:19:13 PDT** under the original bundle ID. A kept its UUID and **9 stored items**; B kept its UUID and **10 stored items**. All pre-update message IDs and immutable contents were compared and preserved; counts include receipt envelopes. [Verification](evidence/physical-build4-install.json), [A launch](evidence/physical-build4-a-launch.txt), [B launch](evidence/physical-build4-b-launch.txt).

The pre-update phone stores contained actual requests and receipts from the user's encounters. Logs report Wi-Fi paths, including `awdl0:wifi` on A and `en0:wifi` on B, with cellular false on those observed paths. Some sessions involved Mac C, and some were route-blocked or incomplete. Neither radio/router isolation nor separate A–B/B–C/B–A timing was established by this observation. **Do not promote this into an offline physical A–E PASS or an infrastructure-independent path verdict.** Payloads were omitted from the recorded physical summaries. [Observation summary](evidence/physical-prebuild4-observations.json), [A paths/events](evidence/physical-prebuild4-a-transport.txt), [B paths/events](evidence/physical-prebuild4-b-transport.txt).

Paid-team build 4 uploaded successfully at **19:18:26 PDT**, completed processing, and is **Testing** in RELAY Development. Test notes saved. The earlier external build 2 submission was not canceled or replaced. [Release record](evidence/testflight-upload-build-4.json), [upload output](evidence/testflight-upload-build-4.txt), [source hashes](evidence/source-sha256-chat-build4.txt). Mac and simulator left paused after UI verification. Next physical step remains a documented no-router test with the updated phones.


## Build 5 — names, addressing, and forwarding-copy presentation (2026-10-23 PDT)

Read both physical stores without recording their payload text. The iPhone 15 Pro Max held 15 envelopes and the iPhone 16 held 16. Two encountered peers used the same old “Relay B” label. Request `ef8e1935-f776-4ae3-905c-24d01d489842` originated on iPhone 16 and was explicitly addressed to Mac UUID `fabb432e-244d-4be8-86eb-eb9ac6982d0f`; iPhone 15 Pro Max held a forwarding copy, and the origin held final receipt `d479e085-336a-461f-a423-b53c3b3c4d9a`. This supports the copy/addressing explanation, not an infrastructure-independent acceptance claim. Existing Chats projection already excluded carried messages; the durable queue exposed payload previews and roles made peers ambiguous. [Sanitized addressing evidence](evidence/physical-prebuild5-addressing.json).

Build 5 adds persistent editable device names, optional backwards-compatible hello `display_name`, peer-name storage migration, and name-based presentation with stable UUID routing. Test roles move to Advanced relay test. Tools explains copies, personal vs forwarded traffic, and normal messaging. The queue now explicitly labels forwarding copies and hides their payload text in both collapsed and expanded views. Names do not authenticate identity; storage/transport are still plaintext. Existing route-test settings are preserved and can be disabled with Use normal messaging.

| Check | Actual result |
|---|---|
| XCTest unit/integration tests | **25 tests, 0 failures**, including legacy hello, bounds/control rejection, legacy schema migration/restart, duplicate names/rename, and three-node personal-chat isolation |
| Separate-process Network.framework TCP control | **PASS**, including partial frame, duplicate suppression, actual relay SIGKILL/restart, separate encounters and return receipt; loopback only |
| iOS Simulator, signed iOS, macOS, paid-team release archive | **PASS**, Xcode 26.1.1 (17B100), macOS 26.6.2 (25G83) |
| Mac rename and restart | **PASS**; UI-saved name retained, UUID unchanged |
| Mac ↔ iOS Simulator name exchange | **PASS**; active rename to RELAY MacBook updated the existing simulator conversation after reconnect; simulator name learned on Mac |
| Queue payload-preview separation | **PASS** in Mac UI; expanded forwarding row shows metadata without payload |
| iPhone 16 / iOS 26.2 | **PASS** install/launch build 5; same UUID, all 16 old envelopes and final receipts preserved, schema migrated to 2, default name iPhone 4E32 |
| iPhone 15 Pro Max / iOS 27.0.1 | **PASS** install build 5 and preservation of all 15 envelopes/UUID/receipts; **launch blocked by device lock**. User asked to unlock/open. Name/schema migration occurs on first launch |
| Paid-team App Store Connect upload | **PASS**, 19:37:57 PDT; processed, internal group **Testing**, test notes saved; external build 2 still Waiting for Review |
| Physical wireless A–E | **NOT TESTED** this session; no controlled radio/router isolation or range-separated encounter evidence |

Mac and simulator are paused after the control. Neither the unit tests, loopback control, nor same-host name exchange verifies an offline wireless path. Final claims remain separate: direct offline P2P **unverified**; physical three-device store/carry/forward **unverified**; physical bidirectional receipt route **unverified**; infrastructure-independent path **unverified**; repeated failures **measured in software controls only**, not physical radios.

Evidence: [25 tests](evidence/automated-tests-build-5.txt), [TCP control](evidence/tcp-control-build-5.txt), [UI checks](evidence/ui-build5-names.json), [actual simulator screenshot](evidence/ui-build5-names-simulator.png), [physical deployment/preservation](evidence/physical-build5-install.json), [iOS build](evidence/build-names-ios-signed.txt), [Mac build](evidence/build-names-macos.txt), [archive](evidence/archive-testflight-build-5.txt), [upload output](evidence/testflight-upload-build-5.txt).


## Private repository packaging — 2026-10-23 PDT

Initialized a standalone Git repository rooted at RELAY, separate from the parent
Dreamer/HPC repository. Added project-specific agent notes, credential/runtime/build
ignore rules, and the explicitly unimplemented shelter/cloud product scope in README.
Source, Xcode project, app assets, tests, scripts, documentation and existing synthetic
test evidence are included. Build outputs, SQLite stores, signing keys/profiles and
credentials are excluded; a staged-path check and secret-pattern scan found no such
files or matching secret values. This scan is a packaging check, not a security audit.

Exported only staged files into a clean temporary directory and ran `swift test` there:
**25 tests passed, 0 failures** at 21:05:35 PDT. This verifies the shared Swift package
can build/test from the repository contents without the original working tree's
ignored files. [Actual clean-export output](evidence/repository-export-tests.txt).
No application/protocol code changed, no new app build was deployed, and no physical
wireless or cloud behavior was verified during repository preparation.

## Build 6 — first shelter request workflow, 2026-10-23 PDT

Implemented a local shelter directory with separate shelter/receiving-device IDs,
copy/share/import codes, structured requests, a draft saved during editing, review
before submit, atomic draft-to-message submission, My requests and a separate Device
inbox. Public navigation is Help / Requests / Shelters / Messages. Tools is under
Help's gear and discovery under Help → Nearby devices. Existing chat and relay data
remain; structured requests are excluded from personal chat and carried requests do
not appear in a relay's request inbox.

These are synthetic local setup/views, not authenticated staff roles. No backend,
Bedrock, ASR, inventory reservation, assignment, or fulfillment action is implemented.
The final-destination receipt still means durable receipt at a device only. Shelter
entries are unverified; storage/transport remain plaintext. Encoded sharing codes
prevent keyboard smart-quote corruption but provide no confidentiality.

| Check | Actual result |
|---|---|
| Core unit/integration suite | **32 tests, 0 failures** (25 existing + 7 shelter cases) |
| New tests | Directory/code round trip and redirect collision; durable draft/restart; atomic idempotent submit; failed-save rollback; legacy schema/data preservation; old-codec payload preservation/destination binding; structured A→B→C→B→A simulated encounters with interruption, B restart, duplicates, receipt and inbox isolation |
| Three-process Network.framework TCP control | **PASS**; actual partial frame, process kill/restart, duplicates and return receipt on loopback. Software control only |
| iOS Simulator, macOS and unsigned iOS device SDK builds | **PASS**, Xcode 26.1.1 (17B100), iOS/macOS 26.1 SDKs, Mac host macOS 26.6.2 (25G83) |
| Mac shelter creation and simulator code import | **PASS** through actual UI; same shelter and receiving-device IDs |
| Help draft restart recovery | **PASS**; simulator process terminated/relaunched before submit, same draft ID, destination, quantity/unit, details and location retained |
| Review and submission | **PASS** after fixing a first-sheet stale state issue. Review shows selected shelter, 20 Packs and People Unknown. Save opens the locally queued request; Help provides a fresh form |
| Mac→simulator control infrastructure | Both endpoints run on this Mac. Normal network configuration unchanged; no isolation attempted. This cannot establish a physical wireless path |
| Simulator request → Mac inbox → simulator return receipt | **PASS** through Bonjour/Network.framework; Mac inbox displayed one request; sender displayed separate final receipt |
| Existing Mac store preservation | **PASS**; all 18 pre-update envelopes, immutable bodies, receipt fields and device UUID compared against a pre-update SQLite snapshot and preserved |
| Physical iPhone build 6 installs/signing, A–E tests | **NOT TESTED** this session; existing physical devices were not updated |
| Build 6 TestFlight upload | **NOT PERFORMED**; earlier distribution status does not imply build 6 availability |

Actual UI-control shelter ID: `d870da24-4cff-42b9-a95e-78fa81018c3e`.
Request: `9a0b709d-552f-4453-9e18-ffccdc80c819`; simulator origin:
`e816be05-b366-4b44-a5dd-8b56ef7e5884`; Mac destination:
`fabb432e-244d-4be8-86eb-eb9ac6982d0f`; return receipt:
`06e6a40a-134d-464c-8599-926221788c82`. Both apps were paused after the control.

Evidence: [32 tests](evidence/automated-tests-build-6.txt),
[TCP control](evidence/tcp-control-build-6.txt),
[UI control record](evidence/ui-build6-shelters.json),
[sender events](evidence/ui-build6-simulator-events.txt),
[receiver events](evidence/ui-build6-mac-events.txt),
[actual simulator receipt screen](evidence/ui-build6-request-receipt.png),
[simulator build](evidence/build-shelters-ios-simulator.txt),
[Mac build](evidence/build-shelters-macos.txt),
[unsigned device build](evidence/build-shelters-ios-unsigned.txt).

Separate physical verdicts remain unchanged: direct offline transfer **unverified**;
physical three-device carry/forward **unverified**; physical return receipt route
**unverified**; router-independent path **unverified**; repeated-failure behavior
**tested in software controls only**. Execute the new shelter extension in TEST_PLAN.md
on physical devices before promoting any of these claims.

### Build 6 TestFlight release follow-up — 2026-10-23 PDT

User explicitly requested shipping build 6. Signed release archive **PASS**, strict
local signature verification **PASS**, App Store Connect upload **PASS** at
**22:36:23 PDT**. Verified archived version 0.1.0 (6), bundle
`com.nikilthalapaneni.relay`, team U4G9LV39GM, iOS minimum 17.0 and unchanged
encryption declaration. Source commit: `180fb8815ea0fe26c9646d2dbecf2430c80ec451`.

Apple processing completed. App Store Connect **RELAY Development → Builds** shows
**0.1.0 (6): Testing**. Saved the build-specific What to Test notes and observed the
Saved state. Apple build ID: `81141f68-484f-4f4c-9afb-9d542a9ac049`.
The existing internal group has one tester, still **Invited**; acceptance/download
on a phone is not verified. No new account privileges or individual invitations
were issued. No physical installation or wireless test was performed in this release.

External build 2 remains **Waiting for Review**. Apple displays that only one build
of version 0.1.0 can be submitted to Beta App Review until the existing build is
approved. The existing submission was not canceled or replaced; build 6 is available
to internal testers, not yet through the external public invitation.

Evidence: [release record](evidence/testflight-upload-build-6.json),
[signed archive](evidence/archive-testflight-build-6.txt),
[successful upload](evidence/testflight-upload-build-6.txt),
[source hashes](evidence/source-sha256-testflight-build-6.txt),
[saved tester notes](evidence/testflight-test-notes-build-6.txt).

### Build 6 physical installation — 2026-10-23 PDT

Updated the original `org.relay.prototype.ios` installations using their existing
Personal Team signing identity, preserving the app containers. The first phone
(iPhone 15 Pro Max, iOS 27.0.1 / 24A446) was connected by USB; the iPhone 16
(iOS 26.2 / 23C55) was also reachable through existing pairing. The first phone
already had a separate `com.nikilthalapaneni.relay` build 6 installed; that copy was
not replaced or deleted. Use the original copies launched by this update consistently
when testing so their existing device UUIDs remain the intended addresses.

Signed device build and strict code-signature verification **PASS**. Install and
launch **PASS on both phones**. Before upgrading, stopped the original app processes
and copied their SQLite directories outside the repository. After launching, copied
the updated stores and verified SQLite integrity, schema 3, stable identities, all
old message IDs/immutable contents and all prior final-receipt fields. First phone:
**19 → 19** envelopes, UUID `d8024643-427c-43dd-a991-7db89543bf19`. Second phone:
**16 → 16**, UUID `4e328dc5-51a9-4e37-92d6-833a81c32078`.

This was installation/data-preservation verification, not a physical delivery test.
Cellular/router/radio isolation was not configured or measured. A–E remain
**NOT TESTED** under the required conditions. No user payloads or databases were
added to evidence. [Installation record](evidence/physical-build6-install.json),
[signed device build](evidence/build-shelters-ios-signed.txt),
[first-phone launch](evidence/physical-build6-a-launch.txt),
[second-phone launch](evidence/physical-build6-b-launch.txt).


## 2026-10-23 23:15 PDT — Build 7 shelter removal and import

- Added reversible local directory removal, a Removed shelters restore list, and
  protection against a stale draft autosave reselecting a removed destination.
  Existing request snapshots, queued messages, final receipts and identities remain.
  Schema stays at 3; the existing metadata table holds removal markers.
- Import has a visible button, Paste, validation and receiving-device preview.
  Whitespace-wrapped codes are accepted within the existing size limit. Copy is
  explicitly local to the source clipboard; Connect is not a prerequisite.
- **PASS:** 35 unit/integration tests, including restart/removal/history retention,
  conflict prevention and malformed/wrapped-code cases. **PASS:** separate-process
  TCP loopback interruption/retry, process restart, duplicates and return receipts.
- **PASS:** iOS simulator, native macOS and development-signed iOS builds; paid-team
  archive and strict app/archive signatures. Xcode 26.1.1, SDKs 26.1, M3 Pro.
- **PASS:** native Mac UI Remove confirmation → hidden entry → Removed shelters →
  Restore; Import opens directly → valid preview/self warning → identical import
  without duplicate entry. Screenshot inspected for usable layout. Simulator build,
  launch and home screenshot passed; simulator action automation failed with
  `noWindowsAvailable`, so interactive checks used the shared native Mac UI.
- **PASS:** direct build 7 install and launch on iPhone 15 Pro Max (iOS 27.0.1 /
  24A446) and iPhone 16 (iOS 26.2 / 23C55), original Personal Team bundle. A used
  USB; B used its paired local-network development connection. Consistent stopped
  pre-update backups and post-update copies passed SQLite integrity checks. A
  retained 24/24 envelopes, 3 final-receipt links and its shelter; B retained 23/23
  envelopes, 4 final-receipt links and its shelter. Bodies/receipts are unchanged.
  Raw phone stores/payloads remain outside Git; evidence records counts only.
- A's saved directory did not contain B's shelter at inspection. No physical user
  shelter was removed by the agent. The separate paid-bundle copy on A remained
  build 6; the original bundle was opened on both phones.
- **NOT TESTED:** physical Remove/Import interaction by the operator; new physical
  shelter transfer; isolated A–E; out-of-range carry; repeated-failure statistics.
  Host and phone radios/infrastructure were not isolated during installation.
  No wireless range, discovery latency or infrastructure independence is claimed.

Evidence: [tests](evidence/automated-tests-build-7.txt),
[TCP control](evidence/tcp-control-build-7.txt),
[Mac UI checks](evidence/ui-build7-shelters.json),
[phone preservation](evidence/physical-build7-install.json),
[iOS simulator build](evidence/build-shelter-removal-ios-simulator.txt),
[Mac build](evidence/build-shelter-removal-macos.txt),
[signed phone build](evidence/build-shelter-removal-ios-signed.txt).

Build 7 paid-team archive/upload also passed: Apple accepted it at 23:12:02 PDT.
Follow-up browser verification confirms processing completed and build 7 is
Testing in RELAY Development. Its build-specific notes were saved with Apple’s
Saved confirmation. The one internal tester is shown with build 6 installed;
no TestFlight build-7 phone installation was checked. External build 2 remains
Waiting for Review. [Archive](evidence/archive-testflight-build-7.txt),
[upload log](evidence/testflight-upload-build-7.txt),
[release record](evidence/testflight-upload-build-7.json).


## 2026-10-24 — Build 8 native cloud and request threads

Implemented native PKCE/Keychain code, authenticated profile/directory, local/cloud
shelter mapping, atomic local-message/cloud-intent persistence, scoped retry queue,
cloud result/history UI, dispatcher/requester replies/progress/cancellation, nearby
request threads and short recording → reviewed transcription input. Added backend
profile/history/event routes with ownership, roles, transitions, revision conflict
and command idempotency. No stock allocation or verified fulfillment is claimed.

| Check | Actual outcome |
|---|---|
| Swift automated suite | **PASS: 43 tests**, including legacy draft decode, atomic outbox rollback/restart, account isolation, exact retry content, PKCE state checks, HTTPS validation and reply dedup/chat exclusion |
| Backend automated suite | **PASS: 35 tests**, including profile, unauthorized history, command replay, transitions/cancellation/restart and concurrent revision conflict |
| Three-process TCP control | **PASS**, interruption/retry/restart/duplicate/return receipt; loopback only |
| iOS Simulator / native Mac / signed iOS builds | **PASS**, Xcode 26.1.1 / SDKs 26.1 |
| Swift → fixture HTTP API | **PASS**, text, WAV, explicit state, duplicate requests/events |
| Swift → real AWS through localhost API | **PASS**, Cognito access token, directory, durable request, Bedrock result, S3 WAV/Transcribe and corrected reviewed text |
| Independent DynamoDB readback | **PASS**, both successful requests, proposals and 3-event histories persisted |
| Mac UI | **PASS**, HTTPS rejection with readable error, request reply/progress queued, reusable composer, Done and screenshot layout inspection; 22 prior envelopes preserved, one new synthetic reply |
| Phone installs / launches / preservation | **PASS**, original bundle; A 28→28 messages and 5 final receipt links, B 27→27 and 4 links; identities and shelters retained |
| Native browser PKCE / refresh / microphone / cloud phone UI | **NOT TESTED**, public HTTPS API absent; CLI tokens are not native sign-in evidence |
| Public API deployment | **BLOCKED**, missing organizer execution role/scoped PassRole; no API URL or deployment |
| Physical A–E / router-independent link / range / repeated failures | **NOT TESTED** in this update |

Actual successful AWS IDs: typed `2774002c-8238-4311-871c-cf820d3a2c92`;
transcription `99599e0d-df75-4712-b28c-522bb4be669b`; explicitly reviewed request
`16764f77-3780-48b6-bd11-8f2a58eb9835`. Transcribe returned “Sheltering needs 2
water packs.” The separate reviewed submission used “Shelter A needs 2 water
packs.” Both validated model proposals reported water_packs, quantity 2, unit pack;
allocation_authorized remained false. This synthetic sample is not noisy-speech
accuracy evidence.

The first live attempt failed with an expired token after already accepting request
`a9622506-46c2-4870-ac10-ee6d90525129`; the Swift journal proves it was not a
zero-write failure. Requester and dispatcher tokens were refreshed privately and
subsequent runs passed. Shared durable counters now read **15 requests / 30** and
**2 transcriptions / 5** (three new request records and one audio job this session).
These are usage bounds, not reconciled dollar charges. No secrets were logged.

Phone A is iPhone 15 Pro Max/iOS 27.0.1 (24A446), B iPhone 16/iOS 26.2 (23C55).
Initial A launch timed out and B was explicitly locked; both passed after the
operator unlocked them. No cellular/router/radio isolation was performed. Saved
phone stores remain outside Git; evidence contains preservation counts only.
Mac synthetic queued reply ID: `e04ac15b-58b4-4e48-bc3c-7f5f0cae7dc6`.

The paid-team build-8 archive/upload succeeded at 23:58:54 PDT on Oct 23. Apple
processing/internal availability is recorded separately; external review is not
implied. Carrier→cloud authentication and trustworthy offline cloud-result return
are still pending; the app refuses to submit another device's request as its own.

Evidence: [Swift tests](evidence/automated-tests-build-8.txt),
[backend tests](evidence/backend-tests-build-8.txt), [TCP control](evidence/tcp-control-build-8.txt),
[fixture HTTP](evidence/swift-http-fixture-build-8.json),
[real AWS HTTP](evidence/swift-http-aws-build-8.json),
[reviewed audio](evidence/swift-http-reviewed-aws-build-8.json),
[DynamoDB readback](evidence/aws-readback-build-8.json),
[Mac UI](evidence/ui-build8-request-thread.json),
[phone preservation](evidence/physical-build8-install.json),
[release](evidence/testflight-upload-build-8.json).

Follow-up: Apple processed build 8; RELAY Development explicitly shows **Testing**.
What to Test notes were saved and confirmed. External build 2 remains Waiting for
Review. No public beta approval or TestFlight build-8 phone installation is inferred.

## 2026-10-24 — build 9 and temporary HTTPS hosting

User authorized Cloudflare hosting after alternatives were checked. The temporary
endpoint is `https://resumes-investigated-striking-mba.trycloudflare.com`, forwarding
through cloudflared 2025.11.1/QUIC to the AWS-mode API on Mac loopback port 8788.
The Python API/worker are on the Mac; this is not an AWS Lambda deployment. A private
configuration copy sets the public URL; the original worker/configuration remain
intact. Internet and ordinary infrastructure were available during these checks.

| Check | Actual result |
|---|---|
| Swift automated suite | **PASS: 43 tests** |
| Backend automated suite | **PASS: 35 tests**, one existing test-client deprecation warning |
| Native Mac and signed iOS builds | **PASS**, Xcode 26.1.1 / SDK 26.1 |
| Public HTTPS health and authorized profile/request reads | **PASS**, including a read after the API restarted with its public-URL config |
| Missing/invalid-token rejection | **PASS**, HTTP 401 on `/v1/me` |
| Private credential filename through public tunnel | **PASS**, HTTP 404; helper is a separate loopback-only server |
| Original-bundle phone upgrade and launch | **PASS** on both, build 9; A 28/28 and B 27/27 prior messages preserved, including exact final-receipt links/shelters/identities |
| TestFlight archive/upload | **PASS**, upload accepted at 00:32:50 PDT; processing completed, build 9 Testing in RELAY Development, test notes Saved; external build 2 still Waiting for Review |
| Native Cognito login | Login page opened with PKCE; **NOT TESTED to completion**, awaiting operator sign-in/MFA |
| Native microphone/WAV picker, phone cloud UI, native refresh/recovery | **NOT TESTED**; implementation/builds are not end-to-end UI evidence |
| Public HTTPS Swift client → real AWS writes/audio | **PASS**, text and reviewed-text requests, WAV upload/Transcribe, Bedrock proposals, lost-response replay and idempotent dispatcher updates |
| Independent DynamoDB readback | **PASS**, both new results and three-event histories; counts 17 requests / 3 audio jobs |
| Inventory reservation/decrement/transfer | **NOT IMPLEMENTED**; reported completion is a human progress event |
| Physical offline A–E, separate encounters, return receipt, router-independent path and repeated-failure metrics | **NOT TESTED** in this update |

Hardware remains iPhone 15 Pro Max / iOS 27.0.1 (24A446), iPhone 16 / iOS 26.2
(23C55), M3 Pro Mac. The previously tested AWS request
`2774002c-8238-4311-871c-cf820d3a2c92` remained `ready_for_review` over public HTTPS.
No discovery or wireless-latency metric was measured. Initial requester-B read
returned 401 because its token was expired; that observation does not establish
cross-account isolation with a valid token.

Follow-up by the existing AWS task refreshed requester-B through its existing MFA
and held the token in memory: B profile/directory 200, A's request/history 404,
dispatcher inbox access 403. Those valid-token isolation checks passed with no
shared token/configuration changes or new paid inference. See
[public HTTPS isolation evidence](evidence/https-isolation-build-9.json).

Subsequent public-URL Swift HTTP tests created typed request
`23187afa-d2a5-4f7c-9677-8c17db31e59b`, transcription
`fea5049d-a3c9-493b-ba7d-8830fbd23d0c`, and explicitly reviewed-text request
`8aecd834-416a-4b7d-9f12-7914eee8b1e6`. The raw synthetic transcript again said
“Sheltering needs 2 water packs.” The agent explicitly corrected it to
“Shelter A needs 2 water packs.” Both Bedrock proposals identified water_packs,
quantity 2, unit pack, allocation_authorized false. Replayed acceptance and three
dispatcher event commands retained one logical request and three history events.
Independent DynamoDB reads confirmed these records and updated counters **17/30
requests, 3/5 transcriptions**. This remains shared-client CLI evidence, not native
browser sign-in, microphone, reviewed-text UI or physical-phone evidence.

New evidence: [public HTTPS text/audio](evidence/swift-https-aws-build-9.json),
[reviewed submission](evidence/swift-https-reviewed-aws-build-9.json),
[durable AWS readback](evidence/aws-readback-build-9.json).

Build 9 adds the bundled HTTPS address and validated WAV import (mono PCM16,
8/16 kHz, ≤60 seconds, ≤2 MiB); macOS uses user-selected read-only file access.
A private local helper displays existing synthetic credentials/current MFA for
the operator without logging them; it is not exposed through the tunnel. It
expires after two hours. No credentials or raw phone databases are committed.

Reproduction and current runtime limits: [DEMO_HOSTING.md](DEMO_HOSTING.md).
Evidence: [HTTPS checks](evidence/https-tunnel-build-9.json),
[phone preservation](evidence/physical-build9-install.json),
[Swift tests](evidence/automated-tests-build-9.txt),
[backend tests](evidence/backend-tests-build-9.txt),
[upload](evidence/testflight-upload-build-9.json).
