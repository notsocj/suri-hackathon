# Suri private demo distribution

## Account setup — 10 October 2026

- App Store listing: **Suri: Scam Check**. Subtitle: **Suri bago sorry.** The installed app displays **Suri**.
- App Store Connect app ID: `6821087318`; SKU: `SURI-IOS`; primary locale: `en-US`.
- Bundle IDs: `ph.suri.app` and `ph.suri.app.share`.
- App Group: `group.ph.suri.app`, registered and assigned to both targets for selected-content intake.
- Internal TestFlight group: **Suri Demo**. No public link or external review submission is configured.
- ASC credentials are stored in macOS Keychain. Private signing files remain outside the repository. Do not commit API keys, private signing keys, PKCS#12 identities, or passwords.

## Latest update — build 5

Version **1.0.0 (5)** was archived from source commit `623f70c` with `CURRENT_PROJECT_VERSION=5` and `DEVELOPMENT_TEAM` passed to Xcode (the project file itself is unchanged), then exported with the existing App Store profiles and the distribution identity loaded into a temporary keychain that was removed afterward. The **2,737,299-byte** IPA is at ignored `.build/Release/Suri-5.ipa`. Both targets verified as signed by the Apple Distribution identity with a valid signature, the `group.ph.suri.app` App Group, `get-task-allow` false, and no device list in the profile; extracted App Intents metadata includes **Check Message Locally**. Apple completed processing with **VALID** status for build `74bfc73f-47ad-4c3d-b39c-83521039353b`, and the upload command assigned it to the internal **Suri Demo** group without notifying testers or submitting for review.

This build adds the guided **Message automation** setup: a card under the Check header, one checklist (turn on, offline checker, run a test, connect incoming messages, confirm it works), a test action that sends the real private warning notification, and a Connected confirmation that stores only a time and result category. It also guards against a Shortcut wired to the sender and skips texts under ten characters. Before upload: 24 core checks, 8 iOS integration checks, and 4 simulator UI checks passed. **Not verified on a physical iPhone:** a real incoming-text trigger, that empty Sender/Message Contains filters do **not** work (iOS keeps Next disabled, observed on the phone, so build 5's step 4 wording was wrong and is corrected in the next build), locked-phone execution and timing, background memory use of the local model, and notification display.

**Known issue in build 5:** the Check Message Locally action hides its Message text field (it was declared as connected to the previous action's result), so a Message automation prompts for text instead of using the received message. Workaround: add **Get Text from Input** before it. Fixed in source after build 5; needs a new build. See [AUTOMATION_SETUP.md](AUTOMATION_SETUP.md).

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
