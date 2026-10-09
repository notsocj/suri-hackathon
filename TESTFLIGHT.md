# Suri private demo distribution

## Account setup — 10 October 2026

- App Store listing: **Suri: Scam Check**. Subtitle: **Suri bago sorry.** The installed app displays **Suri**.
- App Store Connect app ID: `6821087318`; SKU: `SURI-IOS`; primary locale: `en-US`.
- Bundle IDs: `ph.suri.app` and `ph.suri.app.share`.
- App Group: `group.ph.suri.app`, registered and assigned to both targets for selected-content intake.
- Internal TestFlight group: **Suri Demo**. No public link or external review submission is configured.
- ASC credentials are stored in macOS Keychain. Private signing files remain outside the repository. Do not commit API keys, private signing keys, PKCS#12 identities, or passwords.

The physical-device Release archive and App Store IPA export succeeded. The **2,537,536-byte** IPA is at ignored `.build/Release/Suri.ipa`, version **1.0.0 (1)**. Both targets passed signature and App Group entitlement checks, with development debugging disabled.

The IPA was uploaded and Apple completed processing with **VALID** status. Build `4607ab58-47c2-49e2-88ee-0fa2cf236dbf` is explicitly assigned to the internal **Suri Demo** group (`d64aacb8-f304-4836-83d4-f2767e944db8`). Apple reports **READY_FOR_BETA_TESTING** for internal testing. Tester enrollment/invitation is still pending; installation and local inference on a physical iPhone remain unverified. [Open TestFlight](https://appstoreconnect.apple.com/teams/80287bf0-2885-4825-95a4-a8de614a7355/apps/6821087318/testflight).

Automatic export failed because the API key lacks cloud-signing permission. The build was exported with dedicated App Store profiles and the matching local distribution identity in an isolated temporary keychain. The original keychain search list was restored and the temporary identity removed after export. Future exports need access to the protected local signing identity or an appropriately configured Xcode signing account; API authentication alone is insufficient.

## Demo preparation

Install through TestFlight on a physical iPhone, open Suri, and download the pinned **1.28 GB** model in Settings while connected. The download runs in a background session (lock or switch apps freely, but do not force-quit Suri) and can be paused and resumed. It requires a build that includes the background downloader; builds uploaded before 10 October 2026 03:00 use a foreground download that iOS can interrupt, which shows as "cancelled". Model weights are downloaded during setup and are not included in the small application binary. After setup, selected text can be assessed offline.

Use synthetic examples. Verify fresh local input with connectivity disabled, Share to Suri intake, OCR correction, and cancellation on the actual phone. Simulator results do not establish physical-device latency, memory usage, or Messages delivery. Optional Online guidance needs a separately configured HTTPS gateway; localhost on a phone points to the phone itself.

## Export compliance

Both targets declare `ITSAppUsesNonExemptEncryption = false`. The current app uses Apple's operating-system networking, Keychain, file protection, and CryptoKit SHA-256 verification; it does not ship a separate encryption implementation. Reassess this declaration if cryptographic dependencies change. Apple's [documentation table](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption) states that encryption limited to the Apple operating system does not require encryption documentation in App Store Connect.

## Release boundary

This setup is for the authorized private TestFlight demo. App Store public release, external tester invitations, and the hackathon submission are separate actions. Apple processing or review time cannot be guaranteed. The hackathon commit freeze remains **10 October 2026 at 10:00 AM Philippine time**.
