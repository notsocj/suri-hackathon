# Local message automation

## What is implemented

Suri exposes **Check Message Locally** to Apple Shortcuts. The action accepts supplied text, uses the same downloaded Qwen model and evidence validation as manual checks, and never calls Online guidance. It requires explicit permission under **Suri Settings → Message automation → Allow Shortcuts checks**.

Complete validated warning results may create a local notification after Suri notification permission is granted. The notification contains fixed guidance and a result ID, never message text, evidence, an OTP, a sender, a phone number, or a link. It says **Warning signs found**, not that fraud is proven. Ordinary, uncertain, incomplete, and failed checks do not become automatic scam alerts. Notification submission is not proof of display; Focus and notification settings apply.

The app action does not install an incoming-message trigger or read an inbox. The user reported **iOS 26.6.1** and successful manual checking on an iPhone. Actual Message-trigger payloads, locked-phone/background execution, and notification display remain unverified on that phone.

## Setup on the iPhone

Open **Set up** on the Check tab (or Settings → Message automation). One checklist covers everything Suri can do for you; only the trigger itself must be created by hand, because iOS offers apps no way to create a Message automation.

1. **Turn on checks and warnings.** One tap enables Shortcuts checks and asks for notification permission. If notifications were denied before, the step links to iPhone Settings.
2. **Offline checker.** Shows ready, or downloads the 1.3 GB model with progress.
3. **Run a test.** Sends a sample scam message through the same action Shortcuts uses and fires the real warning notification, proving the model, the action and notifications work before touching Shortcuts.
4. **Connect incoming messages.** In Shortcuts: Automation → + → Message; under Message Contains enter a common letter such as `a` (iOS will not continue with both filters empty), or pick a sender instead; choose Run Immediately; add Suri → **Check Message Locally**; set **Message text** to **Shortcut Input**. The step shows this wiring and opens Shortcuts. Apple's native button opens Suri's ready-made action page; no file or iCloud link is needed.
5. **Confirm it works.** After a text arrives and is checked, the step turns to **Connected** and shows when the last text was checked and the result category. Suri stores only that time and category, never the message, sender or evidence, and clears it when checks are turned off.

Guards: if the action receives only a phone number (the Shortcut was wired to the sender), it fails with a message explaining the fix instead of checking the wrong thing. Texts under ten characters are skipped without model work and still count as proof the trigger fired. A repeated identical body is suppressed for five minutes during the same app process.

**Observed on the user's iPhone, iOS 26.6.1, 10 October 2026:** with Sender set to Any Sender and Message Contains empty, the automation's **Next** button stays disabled; entering text in Message Contains lets it continue, and **Run Immediately** is offered. A trigger therefore cannot be created with both filters empty, so "every message" is not achievable through one unfiltered trigger. **Root cause found (build 5):** the action's Message text was declared as connected to the previous action's result, so Shortcuts hid the field (the automation card shows only "Check Message Locally") and, with nothing before it in an automation, asked the user to type a message at run time. The extracted metadata showed `inputConnectionBehavior = 2`; it is now the default (0), so the field is an ordinary editable parameter. **Workaround for build 5:** open the action in the automation and add **Get Text from Input** before Check Message Locally; Check Message Locally then takes its output. **Also observed (first real incoming text):** the trigger fired and Run Immediately ran, but with the action's **Message text** left unconnected Shortcuts stopped and asked the user to type a message. The field starts empty and must be set by tapping it and choosing **Shortcut Input**; if Shortcuts asks for text, it is not connected. A single common letter should match most texts; texts without it (a bare link or number) are not checked, and a second automation using `e` widens coverage because repeated identical text is suppressed. Whether the match is case-sensitive, and how much a letter actually covers, are **unverified** and need a test with real messages. Also unverified: how long a locked-phone run may take, and whether iOS keeps a 1.28 GB model resident in a background Shortcut run are **unverified on the physical phone**. A filtered trigger is not proof that all messages are monitored. If Shortcuts reports an error, treat that message as **not checked** and use manual import.

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
