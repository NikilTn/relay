# Resident setup and walkthrough — build21

Supply choices now include decorative emojis: 💧water, 🥫food, 🛏️blankets,
💊medicines and 📦other. Existing text labels, resource IDs and request payloads
remain unchanged. VoiceOver reads the text label, not a duplicate decorative emoji.
The grid uses one column at accessibility text sizes. Coordinator stock headings
use the same resource symbols.

## First sign-in / first launch after upgrade

An enrolled resident sees two optional steps once per account on each device:

1. Personal details: name, age in years, height in cm, weight in kg, blood group
   (including Not sure / skip), allergies, health conditions, medications, and
   accessibility/support needs. All fields are optional. Save and continue retains
   the entered information; Skip for now proceeds without changing saved details.
2. Six-page walkthrough: requesting help and shelter information, speech/AI review,
   delivery versus staff approval, nearby/offline operation, alerts/read-aloud, and
   personal/accessibility settings. Back, Next and Skip tour are explicit controls.

Completed/skipped steps are saved locally for that signed-in account. A restarted
or upgraded app does not repeatedly present completed setup. Coordinator accounts
do not receive the resident introduction. This is an app introduction after login,
not public self-registration; users still need an enrolled RELAY account.

Residents can reopen **Your details** or **How RELAY works** from the top of Help.
Both are also available from Settings. The walkthrough itself needs no network;
it accurately identifies the features that still require cloud access.

## Personal-data boundary

`ResidentDetails` is intentionally separate from `CloudSubmission`, resource
requests, speech jobs, inventory and relay envelopes. It is **not automatically
included in requests, uploaded to the backend, or sent to Transcribe/Bedrock**.
The current app does not have a per-request profile-sharing feature. A user can
choose to type relevant information into their request, under the existing
request/transcription workflow. Do not infer that staff can see the local profile.

The native vault uses a Keychain generic-password item, with service isolated by
the app bundle ID and account keyed by the endpoint/subject hash. It uses
`WhenUnlockedThisDeviceOnly`, disables Keychain synchronization, and does not log
profile values. Profiles do not sync between devices and are separate between the
original USB-installed app and the paid/TestFlight bundle. The profile remains
saved locally when signing out; it is loaded only for the matching signed-in
account. Clear saved personal details removes that local profile after confirmation.
Uninstall/reinstall Keychain behavior is OS-controlled; do not promise uninstall
as a reliable way to delete a saved Keychain item. Clearing local details does not
delete any information a person has separately typed into an existing request.

The SQLite metadata record contains only `profileOffered` and `guideSeen` flags.
It contains no medical fields. Stored read errors are shown instead of silently
overwriting a locked/unavailable profile. Editing uses a separate draft: Cancel
does not save changes. Number fields reject nonfinite, negative, unit-suffixed or
out-of-range input; blank means unknown. Blood group and all notes are self-reported,
not verified clinical records. No diagnosis, dosage recommendation, inferred blood
type, BMI score or automated triage is added.

The Mac development app is signed ad hoc. A future rebuild may be unable to read
an existing Mac profile because of Keychain access controls; this is surfaced as
a read error. The signed iOS profile was tested across an app update. Production
Mac distribution should use stable signing before promising equivalent behavior.

## Test procedure

1. Update the original phone app to21 and open it with its existing resident login.
   Expect A little about you on the first run of this feature. Use synthetic data
   for the demonstration, or Skip for now. Unknown blood group remains unknown.
2. Save a synthetic profile; navigate all six guide pages, go Back once, finish.
   Help should show the two top links and the supply emojis.
3. Quit/reopen the app. The introduction should not repeat. Your details should
   retain the saved fields. Change a field, Cancel, reopen: original value remains.
4. Reopen How RELAY works from Help, then Settings. It starts at page1 and can be
   closed without changing a request or inventory.
5. Optional manual checks: skip both first-run steps on a new resident account;
   test largest text/VoiceOver, offline profile editing, and Clear on disposable
   test data. Verify another account cannot see the first account's local profile.
6. Confirm the coordinator still opens Inbox directly and stock labels have emojis.

Actual build21 evidence is in `docs/evidence/build21` and `TEST_RESULTS.md`.
The simulator test used only synthetic profile strings. A read-only check found
none of those strings in its request database or WAL; the native relaunch recovered
them from the Keychain. Physical profile entry has been left for the user; no
personal or medical information was entered into either real phone by the agent.
