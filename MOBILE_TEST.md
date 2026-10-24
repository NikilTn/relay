# Test the requester and shelter coordinator

Use build 15 of the original development RELAY app launched by the installer on each phone.
Settings shows the build number. The paid/TestFlight app has a separate store.
This workflow uses internet. Keep the Mac awake, powered and online: its API and
worker run behind the temporary Cloudflare tunnel described in DEMO_HOSTING.md.

## Prepared accounts

- iPhone 15 Pro Max: existing synthetic Requester-A, public Help / Requests / Nearby.
- iPhone 16: existing synthetic Dispatcher-A, coordinator Inbox / Inventory / Nearby.
- Both identities are authorized for Shelter A by the backend. UI labels never grant a role.
- These owned development phones are prepared through a one-use file copied through
  the trusted Mac/device connection. It contains a freshly MFA-authenticated Cognito
  session verified against `/v1/me`, imports into Keychain, and is removed. This
  importer is compiled only in DEBUG; no credential is in the app or repository.
- TestFlight uses the normal email/password/authenticator flow. Accounts are
  pre-enrolled; the Apple account and AWS console account are not RELAY accounts.
  The private helper on the Mac supplies the existing synthetic test credentials.

The request list defaults to Open. Select All or Closed to see completed or released
requests. Extract details is the typed-request preview action. Review request stays at the
bottom; Done dismisses the keyboard. Inventory → Adjust stock expands the adjustment
form. Nearby is separate device chat, not a shelter inbox.

## 1. Make a voice request on the 15 Pro Max

1. Keep internet on. Open Help; Shelter A should already be selected.
2. Tap **Record voice**, permit the microphone, tap Record, and say:
   “Shelter A needs two water packs for one person.” Tap Stop.
3. Tap **Transcribe / resume**. Wait for the transcript and correct any mistakes.
   The tested synthetic sample misheard “Shelter A” as “Sheltering”; review is required.
4. Tap **Prepare request from this text**. Help opens and Bedrock prepares editable
   fields. Verify Water packs and quantity 2. People can be filled manually; do not
   assume the AI extracted a field that remains blank.
5. Tap **Use current location** and choose While Using or Allow Once. Inspect the
   coordinates/accuracy/capture time. If unavailable or declined, add a landmark.
   This captures one snapshot; no ongoing/background location tracking.
6. Tap **Review request**, verify shelter, details, quantity and location, then
   **Send request**. Requests should change from Queued to Waiting for coordinator.
   Note the request ID. A preview alone must never create a shelter request.

Location is included only in authenticated cloud submission in this release.
Precise coordinate metadata is not passed to Bedrock or placed in plaintext nearby
relay messages. A manual landmark and omitted/approximate location are supported.

## 2. Approve on the iPhone 16

1. Open Inbox, select Shelter A and refresh if needed. Open the newest matching
   request and verify its original text, structured fields and location snapshot.
2. Inventory shows On hand / Reserved / Available. The automated synthetic check
   prepared 20 water packs, reserved/fulfilled two, then returned those two test
   packs, leaving 20 available at its last verified snapshot. Check the actual
   current values if anyone has tested since then. Food/blankets start at zero.
3. In the request, review the proposed item and enter 2. Tap **Approve and reserve**.
4. Verify the request shows Approved and supplies reserved. For starting stock 20,
   on-hand stays 20, reserved becomes 2, available becomes 18. No physical handover
   is inferred from this approval.
5. On the requester phone, refresh its request and verify the approval appears.
   Send a coordinator reply and verify the requester sees it.
6. Choose one ending: **Mark supplies handed over**, confirm, then on-hand becomes
   18 and reserved 0; or **Release reservation**, which keeps on-hand 20 and returns
   reserved to 0. Requester cancellation also releases an active reservation.
7. Stock changes are human-reported records. The system cannot independently
   prove that physical supplies were handed over. The model never reserves stock.

## 3. Check failure handling

- Try to reserve more than available: expect a readable rejection and unchanged stock.
- Tap retry after a network interruption: the persisted operation ID prevents a second reservation/deduction.
- Restart after drafting and after sending: the draft/request should survive.
- Turn off internet after account/directory setup, submit a typed request, relaunch,
  restore internet and verify one cloud request. Voice transcription and previews
  require internet; typed fields can still be saved while disconnected.
- Deny location permission, disable Precise Location, and remove location before
  Send. The landmark path must remain usable. Report capture accuracy and timestamp;
  do not invent GPS/range results.

The workshop's current bounded allowance is 30 request/preview analysis slots and
5 transcriptions shared by all clients. After automated and Mac UI acceptance checks,
19 analysis slots and 4 transcription allocations had been used (08:52 UTC); one audio allocation remained. Replaying the same operation
or sending an already prepared preview does not consume a second analysis slot.
Record new tests before increasing an approved budget. The location/map link may
need internet; a GPS fix itself depends on available sensors and surroundings.

## Separate offline demo

The Nearby tab still supports nearby discovery, durable forwarding and return receipts.
Discovery starts automatically while the app is open; foreground encounters are
required. Settings → Developer tools retains the existing offline shelter form,
directory and diagnostics. Follow TEST_PLAN.md for no-router A–E evidence.

The new cloud request composer does not yet implement an authenticated
carrier-to-cloud gateway or encrypted cross-transport location forwarding. Its
cloud outbox waits for that origin device to reconnect. Do not claim a stranger's
phone can upload the request under the origin account, or that a cloud reply already
travels back through a trusted offline gateway. New cloud records and existing P2P
messages remain distinct durable flows.
