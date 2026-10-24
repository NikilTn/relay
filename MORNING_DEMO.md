# RELAY morning demo — build19

The smallest clear demo is **two requester iPhones and this Mac as Shelter A**.
Use the native apps. There is no separate dispatcher website to configure.

The API is **https://relay.stepcheck.app**. Real AWS Transcribe, Bedrock and the
inventory ledger are behind the Mac-hosted API. The hostname is stable, but this
Mac, its internet connection, API, worker and current tunnel must stay running for
cloud features. See [hosting](cloud/docs/DEMO_HOSTING.md).

## Before presenting

1. Check Settings → Demo tools → Build19 on each app. The new TestFlight package
   was uploaded, but check its availability before assuming your friends have it.
   At approximately08:00PDT both original development phone apps were updated to19 and launched.
   Existing identities, messages and receipts were preserved. Physical wireless
   acceptance is still a separate test.
2. Use **Requester A** on the15 Pro Max, **Requester B** on the iPhone16, and
   **Coordinator A** on the Mac. These are the existing synthetic test accounts.
   Account switching happens in Settings; roles are assigned by the backend.
   The iPhone16 was switched to existing RequesterB during installation; its old coordinator history remains saved under that account.
3. With internet available, open all three apps. On the Mac, Settings must say
   **This device receives nearby shelter requests**. Otherwise choose **Receive
   shelter requests here** for Shelter A. On each phone, select Shelter A and wait
   for **Cloud + nearby delivery**. This caches the receiver address and keys.
4. Allow Local Network access. Allow microphone/location only when testing those
   features. Keep RELAY in the foreground and devices awake during encounters.
5. Keep the Mac powered with its lid open. The eight-hour keep-awake session was
   started around03:19 PDT; extend it if presenting later. Do not restart the
   existing tunnel just before the demo. Verify API/account access first. The AWS workshop session expired overnight and was renewed; run the hosting preflight again before presenting.
6. Use synthetic requests. Do not delete apps or clear their stores. TestFlight
   and the original USB app have different bundle IDs and separate identities;
   install/update the same app on each phone for a consistent demonstration.

## Demo1 — voice → structured request → supplies

Keep internet available on all devices.

1. On requester A, Ask for help → Shelter A → Speak → Start recording.
2. Say: **“This is a test. We need two water packs for two people at the north
   entrance.”** Stop. Partial words should appear while speaking.
3. Review/correct the final transcript. Choose Use this text; review the extracted
   item/quantity. Fill unknown fields manually. The model does not approve supplies.
4. Choose Use my location, or type a landmark. Verify the displayed snapshot and
   time. Review request → Send request.
5. On Mac Inbox, open that request. Verify the original text, fields and location.
   Choose Approve and reserve for2 water packs. Available stock should fall by2;
   on-hand stock should stay unchanged while reserved.
6. Record handover only as a **synthetic test**. Confirm. Reserved stock decreases
   and on-hand stock decreases by2. The phone should show the updated status.

The overnight UI rehearsal performed this flow with synthetic typed text/Bedrock,
reservation and handover. Actual AWS live streaming was tested with a native Swift
client sending synthetic WAV chunks. **Your physical phone microphone and GPS
still need this morning check.** Correct transcription errors before sending.

## Check the new extraction and tags

Try: “We have no internet. We need two water packs for four people in room12,
urgently.” With cloud available, Extract details should fill Water packs /2 /4 /
room12 /Urgent. Change Urgent to Soon manually and verify Review keeps your choice.
The phrase “no internet” is test narrative here, not evidence of radio isolation.

Try a synthetic medicine request: “We need two inhalers for three people at the
north entrance, right now.” Review the medicine/details and Immediate tag. Staff
see it in Inbox and can reply; generic medicine reservation is deliberately absent.
No medicine is recommended by the model. Use only synthetic medical test data.

Keep a request detail open on the phone and send a reply from the Mac. It checks
for updates about every3seconds while foreground; internet latency adds to that.
The request list refreshes about every8seconds. Offline staff replies still wait
for cloud recovery; only the signed destination receipt returns through nearby.

## Demo2 — nearby shelter delivery

For an easy rehearsal, use Settings → Demo tools → **Pause cloud delivery (demo)**
on each requester. Keep the Mac's cloud active. This demonstrates the application's
nearby route; it is explicitly **not proof of physical internet/radio isolation**.

1. Send a short new typed request to Shelter A. It should first be saved locally.
2. The Mac should receive it in Inbox. The phone should show **Shelter receipt
   verified**, separately from cloud acceptance or staff approval.
3. The Mac can upload the sender-signed request when online. The request remains
   owned by the original requester. Resume cloud on the phone; it must reconcile
   the same request, not create another allocation or logical request.

For the physical infrastructure-independent test, additionally disable cellular,
disconnect every participant—including the Mac—from ordinary Wi-Fi networks and
Ethernet/router paths, and verify those conditions. **Keep Wi-Fi radios on**;
leave Bluetooth enabled for the baseline. Turning Wi-Fi off disables the required
local wireless capability. Airplane mode may require manually re-enabling radios.
The backend's cloud features will be unavailable while the Mac has no internet;
its cached native shelter inbox can still receive and persist nearby requests.
Use a typed request and a landmark for this isolated test. Do not claim that a
Wi-Fi icon, `includePeerToPeer`, or a simulator proves the path was router-free.

## Demo3 — the store-carry-forward proof

Use a fresh message so earlier direct delivery cannot be mistaken for relay success.

1. Cache Shelter A's receiver while online. Pause requester cloud delivery or
   remove internet access as appropriate to the stated test.
2. End the Mac app's encounter with both phones. Keep only A and B active together.
3. A sends a new request addressed to Shelter A. Verify A says a relay saved it,
   and verify B's diagnostics show its message ID. It must not say final delivered.
4. End A's encounter. Terminate and relaunch RELAY on B. Verify the message remains.
5. Open the Mac with B while A remains disconnected. Verify receipt in the Mac
   inbox and creation of a destination receipt. B retains that receipt.
6. End the Mac encounter. Reconnect B with A later. A must show the verified shelter
   receipt. A, B and C never need a continuous end-to-end route.

This exact app-lifecycle sequence passed overnight on two native iPhone simulators
and the native Mac, including two B app restarts and a two-hop return receipt.
All lived on one computer: that proves software encounter separation, not physical
radio range/separation. Repeat on your phones and, if practical, with A/C genuinely
out of range. Label a close-range forced route as a logical relay test.

## If something stalls

- No nearby delivery: confirm same shelter receiver, Local Network permission,
  foreground apps, enabled radios and cached setup. Check Settings → Nearby
  messages / Demo tools → Diagnostics. Do not select random neighboring phones as
  the final destination for a shelter request.
- Cloud unavailable: keep the saved request. Resume cloud and retry the same ID.
  A domain does not repair a sleeping Mac, stopped tunnel or expired AWS session.
- Speech interrupted: the WAV is retained. Retry checks the original live session
  before creating another explicit transcription job. Typing remains available.
- Location denied/stale: use a landmark. The app does not fabricate a fresh fix.
- Inventory conflict: refresh stock and review again. Do not keep pressing approval
  or interpret a delivery receipt as approval.
- Offline staff reply/stock update: these currently synchronize through cloud.
  Nearby transport returns the signed delivery receipt; it does not yet carry the
  cloud inventory history or the request's staff conversation.

## What to tell judges

“RELAY uses AWS for speech, interpretation and coordinated inventory when connected.
Requests are durably saved. When cloud delivery is unavailable, nearby Apple devices
can carry an encrypted request to an enrolled shelter receiver, with a signed
receipt returning later. Staff control resource approval.”

Be explicit that API compute currently runs on this Mac. Claim physical router-free
operation only after documenting the actual phone test conditions. Do not claim
background delivery, Android interoperability, production security, guaranteed
range, or disaster resilience from this prototype.
