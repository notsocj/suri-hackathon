# Suri private demo distribution

## Account setup — 10 October 2026

- App Store listing: **Suri: Scam Check**. Subtitle: **Suri bago sorry.** The installed app displays **Suri**.
- App Store Connect app ID: `6821087318`; SKU: `SURI-IOS`; primary locale: `en-US`.
- Bundle IDs: `ph.suri.app` and `ph.suri.app.share`.
- App Group: `group.ph.suri.app`, registered and assigned to both targets for selected-content intake.
- Internal TestFlight group: **Suri Demo**. No public link or external review submission is configured.
- ASC credentials are stored in macOS Keychain. Private signing files remain outside the repository. Do not commit API keys, private signing keys, PKCS#12 identities, or passwords.

## Latest update — build 4

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
