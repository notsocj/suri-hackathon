# Suri private demo distribution

## Account setup — 10 October 2026

- App Store listing: **Suri: Scam Check**. Subtitle: **Suri bago sorry.** The installed app displays **Suri**.
- App Store Connect app ID: `6821087318`; SKU: `SURI-IOS`; primary locale: `en-US`.
- Bundle IDs: `ph.suri.app` and `ph.suri.app.share`.
- App Group: `group.ph.suri.app`, registered and assigned to both targets for selected-content intake.
- Internal TestFlight group: **Suri Demo**. No public link or external review submission is configured.
- ASC credentials are stored in macOS Keychain. Private signing files remain outside the repository. Do not commit API keys, private signing keys, PKCS#12 identities, or passwords.

## Latest update — build 10

Version **1.0.0 (10)** was archived from source commit `136f252` (build number and team passed to Xcode; project file unchanged) and exported with the existing App Store profiles and the distribution identity in a temporary keychain removed afterward. The **2,819,646-byte** IPA is at ignored `.build/Release/Suri-10.ipa`. Both targets verified as Apple Distribution signed with valid signatures, the `group.ph.suri.app` App Group, `get-task-allow` false, and build number 10; the App Intents metadata lists Check Message Locally (`inputConnectionBehavior = 0`) and Check Copied Message, and the binary contains the heads-up copy. Apple completed processing with **VALID** status for build `464a9f63-d5e3-46b7-b021-a1bb32b12a76`, assigned to the internal **Suri Demo** group without notifying testers or submitting for review.

This build adds the instant **"Wait! Hayaan mo si Suri suriin ito."** heads-up for incoming texts that mention money, a code, a promo, an account or a link, replaced in place by the result. No change to an existing automation is needed. Before archiving: 27 core and 10 iOS integration checks passed, including one that reads delivered notifications in the simulator. **User report on the phone (10 October 2026):** the incoming-SMS automation works with the heads-up followed by Suri's result, Check Copied Message works from the Action Button, and Ask my family works. **Still unverified:** locked-screen runs, timing, Siri/Spotlight triggers, and an airplane-mode check.

## Previous update — build 9

Version **1.0.0 (9)** was archived from source commit `0fd3fb9` (build number and team passed to Xcode; project file unchanged) and exported with the existing App Store profiles and the distribution identity in a temporary keychain removed afterward. The **2,812,110-byte** IPA is at ignored `.build/Release/Suri-9.ipa`. Both targets verified as Apple Distribution signed with valid signatures, the `group.ph.suri.app` App Group, `get-task-allow` false, and build number 9; the extracted App Intents metadata lists **Check Message Locally** (Message text `inputConnectionBehavior = 0`) and **Check Copied Message**. Apple completed processing with **VALID** status for build `acc0f366-047b-49ad-8884-cad7cd11e209`, assigned to the internal **Suri Demo** group without notifying testers or submitting for review.

This build adds the lowercase wavy "suri bago sorry." wordmark, moves the typing Done button into the Message heading, and adds **Check Copied Message** for Messenger and other apps. It includes build 8's early-answer fix. Before archiving: 24 core, 10 iOS integration, and 4 simulator UI checks passed, and Check Copied Message was run end to end from Shortcuts in the simulator. **Unverified on the phone:** the early-answer fix, locked-screen runs, Check Copied Message and the Action Button.

## Previous update — build 8

Version **1.0.0 (8)** was archived from source commit `5c62c89` (build number and team passed to Xcode; project file unchanged) and exported with the existing App Store profiles and the distribution identity in a temporary keychain removed afterward. The **2,795,539-byte** IPA is at ignored `.build/Release/Suri-8.ipa`. Both targets verified as Apple Distribution signed with valid signatures, the `group.ph.suri.app` App Group, `get-task-allow` false, build number 8, and Message text `inputConnectionBehavior = 0`. Apple completed processing with **VALID** status for build `6fb3c969-dade-4f0e-b319-4229bd004afb`, assigned to the internal **Suri Demo** group without notifying testers or submitting for review.

This build addresses the build 7 failure where Shortcuts reported "unknown error" on a longer incoming text although Suri had saved the result: the action answers within 20 seconds while the check finishes under a background-time request, notification errors no longer fail the run, and setup shows the last automatic run's stage and timing. Results gained a back button and an "Incoming text" label when opened from a Suri notification. Before archiving: 24 core, 9 iOS integration, and 4 simulator UI checks passed. **Unverified on the phone:** whether 20 seconds is within Shortcuts' limit, whether iOS grants enough background time to finish, and locked-phone behaviour.

## Previous update — build 7

Version **1.0.0 (7)** was archived from source commit `544b28d` with `CURRENT_PROJECT_VERSION=7` and `DEVELOPMENT_TEAM` passed to Xcode (project file unchanged) and exported with the existing App Store profiles and the distribution identity in a temporary keychain removed afterward. The **2,772,684-byte** IPA is at ignored `.build/Release/Suri-7.ipa`. Both targets verified as Apple Distribution signed with valid signatures, the `group.ph.suri.app` App Group, `get-task-allow` false, and build number 7; the extracted metadata still shows `inputConnectionBehavior = 0` for Message text. Apple completed processing with **VALID** status for build `a2063c36-f0e1-476c-8799-d94aa5736d7d`, and the upload command assigned it to the internal **Suri Demo** group without notifying testers or submitting for review.

This build replaces the text-heavy step 4 of Message automation with a **Show me how** button opening a one-page list of eight numbered steps, with the common mistakes (picking Suri from the list, Ask Each Time, tapping the ✕ instead of Done) called out and Open Shortcuts pinned at the bottom. Every instruction was walked through on the iPhone 17 Pro simulator (iOS 26.5); **no real incoming text has yet been checked on the physical iPhone**, and locked-phone execution, timing, background memory use and single-letter filter coverage remain unverified.

## Previous update — build 6

Version **1.0.0 (6)** was archived from source commit `4a1abec` with `CURRENT_PROJECT_VERSION=6` and `DEVELOPMENT_TEAM` passed to Xcode (project file unchanged), exported with the existing App Store profiles and the distribution identity in a temporary keychain removed afterward. The **2,737,737-byte** IPA is at ignored `.build/Release/Suri-6.ipa`. Both targets verified as Apple Distribution signed with valid signatures, the `group.ph.suri.app` App Group, `get-task-allow` false, and build number 6. Apple completed processing with **VALID** status for build `915e3769-62b3-472f-bec9-3d39c61c7839`, and the upload command assigned it to the internal **Suri Demo** group without notifying testers or submitting for review.

This build fixes the build 5 Message automation issue: the action's **Message text** is now an ordinary editable field (extracted metadata shows `inputConnectionBehavior = 0`, previously 2), and setup step 4 says to enter a common letter in Message Contains, tap Message text and choose Shortcut Input. After installing, open the existing automation, remove the old Check Message Locally action and add it again so Shortcuts picks up the new field. Eight iOS integration checks passed before archiving. **Still unverified on the physical iPhone with this build:** the corrected automation running on a real incoming text, locked-phone execution and timing, background memory use of the local model, and how much a single-letter filter covers.

## Previous update — build 5

Version **1.0.0 (5)** was archived from source commit `623f70c` with `CURRENT_PROJECT_VERSION=5` and `DEVELOPMENT_TEAM` passed to Xcode (the project file itself is unchanged), then exported with the existing App Store profiles and the distribution identity loaded into a temporary keychain that was removed afterward. The **2,737,299-byte** IPA is at ignored `.build/Release/Suri-5.ipa`. Both targets verified as signed by the Apple Distribution identity with a valid signature, the `group.ph.suri.app` App Group, `get-task-allow` false, and no device list in the profile; extracted App Intents metadata includes **Check Message Locally**. Apple completed processing with **VALID** status for build `74bfc73f-47ad-4c3d-b39c-83521039353b`, and the upload command assigned it to the internal **Suri Demo** group without notifying testers or submitting for review.

This build adds the guided **Message automation** setup: a card under the Check header, one checklist (turn on, offline checker, run a test, connect incoming messages, confirm it works), a test action that sends the real private warning notification, and a Connected confirmation that stores only a time and result category. It also guards against a Shortcut wired to the sender and skips texts under ten characters. Before upload: 24 core checks, 8 iOS integration checks, and 4 simulator UI checks passed. **Not verified on a physical iPhone:** a real incoming-text trigger, that empty Sender/Message Contains filters do **not** work (iOS keeps Next disabled, observed on the phone, so build 5's step 4 wording was wrong and is corrected in the next build), locked-phone execution and timing, background memory use of the local model, and notification display.

**Known issue in build 5 (fixed in build 6):** the Check Message Locally action hides its Message text field (it was declared as connected to the previous action's result), so a Message automation prompts for text instead of using the received message. Workaround: add **Get Text from Input** before it. Fixed in build 6. See [AUTOMATION_SETUP.md](AUTOMATION_SETUP.md).

## Previous update — build 4

Version **1.0.0 (4)** streamlines Message automation into three steps and adds Apple's native button opening Suri's App Shortcuts page. The ready-made checking action is included with the app; no shortcut download or public iCloud link was created. Its preceding-input connection is enabled in extracted metadata. The targeted real-action integration check passed, as did the device archive, signature checks, and metadata checks. The **2,658,224-byte** IPA is at ignored `.build/Release/Suri-4.ipa`. Apple processing completed with **VALID** status for build `e97d94d6-4d1d-4de9-96c9-197e8563b0f0`. Native-button navigation and real Message-trigger execution still need verification on the user's phone.

## Previous update — build 3

Version **1.0.0 (3)** adds opt-in **Check Message Locally** for Shortcuts and private local warning notifications. The **2,648,612-byte** IPA is at ignored `.build/Release/Suri-3.ipa`, with valid distribution signatures, matching App Group entitlements, and extracted App Intents metadata. Core safety checks passed (21), existing UI checks passed (4), and final iOS integration checks passed (7), including direct invocation of the real local action and duplicate suppression. These small tests are not an accuracy benchmark or a live incoming-SMS test.

Apple completed processing with **VALID** status. Build `f67d6fec-f2cc-480a-aefc-b1463988de05` is explicitly assigned to **Suri Demo** and reports **IN_BETA_TESTING**. App-side automation requires the user to configure a Message trigger and pass its received body in Shortcuts. Live SMS-trigger execution, locked/background behavior, and notification display remain unverified on the reported iOS 26.6.1 phone. Messenger/other-app notification monitoring is unavailable on this OS. Read [AUTOMATION_SETUP.md](AUTOMATION_SETUP.md) before testing.

## Previous update — build 2

Version **1.0.0 (2)** was archived from source commit `4b6ed7d` with `CURRENT_PROJECT_VERSION=2` passed to Xcode for both targets. The **2,563,023-byte** IPA is at ignored `.build/Release/Suri-2.ipa`. Both targets passed distribution signature and App Group entitlement checks, with development debugging disabled. All **16 core checks, 5 iOS integration checks, and 4 simulator UI checks** passed before upload.

This build includes the redesigned interface, new icon, capsule buttons, updated typography, and background model downloading with progress and pause/resume. Apple completed processing with **VALID** status. Build `9b80e079-20ff-4b72-ae8b-2d3e19ef66c9` is explicitly assigned to **Suri Demo** and reports **IN_BETA_TESTING** for internal testing, with no export-compliance blocker. Physical-device background download behavior, inference performance, and Messages delivery still need verification.

## Previous update — build 1

The first physical-device Release archive and App Store IPA export succeeded. The **2,537,536-byte** IPA is at ignored `.build/Release/Suri.ipa`, version **1.0.0 (1)**. Both targets passed signature and App Group entitlement checks, with development debugging disabled.

The first IPA was uploaded and Apple completed processing with **VALID** status. Build `4607ab58-47c2-49e2-88ee-0fa2cf236dbf` is explicitly assigned to the internal **Suri Demo** group (`d64aacb8-f304-4836-83d4-f2767e944db8`). Apple reports **READY_FOR_BETA_TESTING** for internal testing. Tester enrollment is managed separately; installation and local inference on a physical iPhone remain unverified by this upload workflow. [Open TestFlight](https://appstoreconnect.apple.com/teams/80287bf0-2885-4825-95a4-a8de614a7355/apps/6821087318/testflight).

Automatic export failed because the API key lacks cloud-signing permission. The build was exported with dedicated App Store profiles and the matching local distribution identity in an isolated temporary keychain. The original keychain search list was restored and the temporary identity removed after export. Future exports need access to the protected local signing identity or an appropriately configured Xcode signing account; API authentication alone is insufficient.

## Demo preparation

Install **build 2 or later** through TestFlight on a physical iPhone, open Suri, and download the pinned **1.28 GB** model in Settings while connected. Build 2 uses a background session and supports pause/resume; verify lock-screen and app-switch behavior on the demo phone, and do not force-quit Suri. Build 1 used a foreground download that iOS can interrupt, showing "cancelled". Model weights are downloaded during setup and are not included in the small application binary. After setup, selected text can be assessed offline.

Use synthetic examples. Verify fresh local input with connectivity disabled, Share to Suri intake, OCR correction, and cancellation on the actual phone. Simulator results do not establish physical-device latency, memory usage, or Messages delivery. Optional Online guidance needs a separately configured HTTPS gateway; localhost on a phone points to the phone itself.

## Export compliance

Both targets declare `ITSAppUsesNonExemptEncryption = false`. The current app uses Apple's operating-system networking, Keychain, file protection, and CryptoKit SHA-256 verification; it does not ship a separate encryption implementation. Reassess this declaration if cryptographic dependencies change. Apple's [documentation table](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption) states that encryption limited to the Apple operating system does not require encryption documentation in App Store Connect.

## Release boundary

This setup is for the authorized private TestFlight demo. App Store public release, external tester invitations, and the hackathon submission are separate actions. Apple processing or review time cannot be guaranteed. The hackathon commit freeze remains **10 October 2026 at 10:00 AM Philippine time**.
