# Local message automation

## What is implemented

Suri exposes **Check Message Locally** to Apple Shortcuts. The action accepts supplied text, uses the same downloaded Qwen model and evidence validation as manual checks, and never calls Online guidance. It requires explicit permission under **Suri Settings → Message automation → Allow Shortcuts checks**.

Complete validated warning results may create a local notification after Suri notification permission is granted. The notification contains fixed guidance and a result ID, never message text, evidence, an OTP, a sender, a phone number, or a link. It says **Warning signs found**, not that fraud is proven. Ordinary, uncertain, incomplete, and failed checks do not become automatic scam alerts. Notification submission is not proof of display; Focus and notification settings apply.

The app action does not install an incoming-message trigger or read an inbox. The user reported **iOS 26.6.1** and successful manual checking on an iPhone. Actual Message-trigger payloads, locked-phone/background execution, and notification display remain unverified on that phone.

## Setup on the iPhone

Build 4 adds Apple's native Shortcuts button to open Suri's preconfigured App Shortcut page. The checking action is included with the app; a separate signed file or iCloud share link is not required. Its text parameter connects to preceding action output where Shortcuts supports that connection, but verify that the received message body is the value passed. The Message trigger remains specific to each device and must be configured by the user. Sharing a normal shortcut does not establish an incoming-message trigger on the recipient's iOS 26 phone. [Apple App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts?changes=_4__8), [native Shortcuts button](https://developer.apple.com/documentation/appintents/shortcutslink?language=objc__5), [device-specific automations](https://support.apple.com/en-gb/guide/shortcuts/apd690170742/9.0/ios/26).

1. Install the TestFlight build containing this action. Complete the model download first.
2. In Suri Settings, open **Message automation**, enable **Allow Shortcuts checks**, and tap **Allow warning notifications**. If previously denied, enable Suri alerts in iPhone Settings → Notifications.
3. Tap the native Shortcuts button under **Open the ready-made shortcut** to find Suri's **Check Message Locally** action. No separate download is needed. For a manual test, use a **Text** action containing synthetic input followed by the Suri action; confirm the text parameter is connected to that output.
4. Create a **Message** personal automation. Begin with the second phone's sender, or a Message Contains filter supported by the phone. Choose **Run Immediately** if offered.
5. Add **Check Message Locally**. Set **Message text** to the received message **body** from **Shortcut Input**. Use Get Text from Input if conversion is needed. Do not pass just the sender, notification title, or a fixed example.
6. Send a synthetic message from the other phone, and verify that the received body—not a cached example—is checked. Then test while the screen is locked and while Suri is not open. Disable Wi-Fi to verify the analysis has no cloud dependency; receiving SMS still needs carrier connectivity.
7. Send a benign OTP delivery and an urgent appointment reminder. They should not produce unsupported warning alerts. Send a duplicate warning message; a repeated identical body is suppressed for five minutes during the same app process.

Apple documents Message automation filters for **Sender** and **Message Contains**. Configure only the coverage offered by the phone. A filtered trigger is not proof that all messages are monitored. Automations, permissions, truncation, battery/resource restrictions, and system termination can prevent execution. If Shortcuts reports an error, treat that message as **not checked** and use manual import.

## Messenger and other chat apps

Suri cannot read another app's notification inbox through UserNotifications. Apple's iOS 27 guide documents a broader Notification trigger; the checked iOS 26 guide does not list it. The user's iOS 26.6.1 phone therefore uses **Share to Suri**, screenshot import, or copied text for those apps. A chat app may provide its own Shortcuts actions; no such integration has been validated here.

## Consent, storage, and cancellation

- Turning off Shortcuts checks cancels the active automated check and removes pending Suri warning requests. No text is queued for later or uploaded.
- At most one automated check runs at a time. Another message gets an explicit busy error rather than an invented result.
- Duplicate fingerprints are salted, ephemeral, and bounded; they are not persisted. Duplicate suppression resets when the app process is restarted.
- Save check history also applies to automated checks. Only the normal validated result/evidence is saved, not the full input. Protected history can be unavailable while locked; this does not turn a completed assessment into a clean result or prevent a permitted warning.
- Tapping a warning opens the saved result when available. If history was off or the protected save failed, Suri explains that the result is unavailable and asks for manual review.
- No family message is sent automatically. This feature warns the phone owner only.

## Verification status

Deterministic checks cover private notification copy, incomplete/urgency-only input, ordinary/uncertain results, duplicate work, and retry after failure. An iOS integration check invokes the real App Intent with fresh synthetic input and checks opt-in enforcement and duplicate suppression. This direct invocation is not a test of iOS receiving a live SMS and triggering Shortcuts.

A benign OTP example with an appended random reference produced uncertain or conflicting model output during development. Conflicting output was rejected, and the action failed rather than creating a fabricated result. The final action smoke test uses the established benign OTP case. These checks do not establish reliable classification of every new message; real-device testing must include changed wording and explicit failure handling.

Sources: [Apple communication triggers](https://support.apple.com/en-az/guide/shortcuts/apdd711f9dff/ios), [iOS 26 automation creation](https://support.apple.com/en-az/guide/shortcuts/apdfbdbd7123/9.0/ios/26), [Apple App Intents](https://developer.apple.com/documentation/appintents/appintent), [local notification scheduling](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app). SDK availability and intent modes were checked against the installed iOS 26.5 AppIntents interface.
