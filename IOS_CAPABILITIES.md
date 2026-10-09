# Suri Apple platform feasibility

Evidence checked **9 October 2026**. Documented capability and observed behavior on the user's phone are different statuses. The current native app implements selected screenshot/text import, Vision OCR, local Qwen inference, and Share intake. OCR, local inference, Keychain, and host App Group intake have passed simulator checks. Full physical-device behavior, notification automation, message filtering, and actual messaging delivery remain untested. Share Extension UI and resource behavior require a separate walkthrough; compilation alone does not verify every host app.

## Capability matrix

Update — 10 October 2026: the user reports iOS 26.6.1 and successful manual checking. A local-only App Intent and owner warning notifications are implemented. Compilation/direct action tests do not validate a real Message trigger, locked/background execution, or notification display. See [AUTOMATION_SETUP.md](AUTOMATION_SETUP.md). Other chat apps continue to use selected-content sharing/import on this OS.

Observed on the user's iPhone (iOS 26.6.1), 10 October 2026: a personal **Message** automation fires on real incoming SMS and offers **Run Immediately**; it cannot be saved with both Sender and Message Contains empty; an App Intent with an unconnected required parameter makes Shortcuts prompt for text at run time; a long-running background App Intent was reported by Shortcuts as "unknown error" although the app had saved its result. Messenger messages are not available to any iOS 26 trigger.

| Capability | Status | Product consequence |
| --- | --- | --- |
| Screenshot/photo import | Documented | Reliable initial input path |
| Share Extension receiving supported text/images/links | Documented | Build Share to Suri; host apps decide which content they expose |
| On-device OCR | Documented | Extract selected screenshots without a cloud call |
| On-device language generation/classification | Documented on eligible, ready systems | Verify device/model availability and output quality |
| App directly listing Messenger/Facebook notifications | Unsupported by normal app notification APIs | Do not build around a device-wide notification inbox |
| User-configured iOS 27 Notification trigger | Documented; payload/execution untested | Possible bridge into an App Intent; must validate each app |
| User-configured iOS 27 Screenshot trigger | Documented; execution untested | Potential automatic processing of selected screenshot events |
| iOS 26 equivalent Notification/Screenshot triggers | Not listed in the checked versioned guide | Do not assume the iOS 27 guide applies |
| Incoming Messages/Email Shortcuts automation | Documented | Separate path from third-party chat notifications; test actual input and action behavior |
| Unknown-sender SMS/MMS filter | Documented | Separate extension for eligible carrier messages |
| Universal RCS filtering | Unresolved | Verify OS/carrier/encryption behavior on-device |
| App-controlled iMessage sending without a send action | No unrestricted standard API established | Use reviewed composer, validated user Shortcuts, or another transport |
| Critical Messaging API | Documented conditional capability | Critical SMS, not iMessage; do not make MVP depend on eligibility |
| Backend SMS or push | Ordinary network service | Needs credentials/configuration, connection, and delivery-state handling |

## Direct notification APIs

`getDeliveredNotifications` returns the containing app's delivered notifications. A `UNNotificationServiceExtension` processes qualifying remote notifications for that app. Neither gives Suri another app's notification inbox. [Apple notification API](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/getdeliverednotifications%28completionhandler%3A%29), [Notification service](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)

Do not propose changing Messenger's notifications, inserting a warning inside its native UI, or silently reading its complete conversations.

## Shortcuts automation correction

Apple's iOS 27 guide lists a Notification trigger with an app selector and filters for Message, Subtitle, or Title. It also lists Screenshot triggers for Photos, Files, or Clipboard. These suggest a user-configured automation route. They do not establish the exact input passed to Suri, unrestricted background execution, or availability of hidden/truncated notification text. [iOS 27 event triggers](https://support.apple.com/en-jo/guide/shortcuts/apd932ff833f/ios)

The checked [iOS 26 guide](https://support.apple.com/en-jo/guide/shortcuts/apd932ff833f/9.0/ios/26) omits those triggers. The current execution guide lists automatically runnable Message/Email automations but does not explicitly resolve Notification/Screenshot confirmation behavior. [Automation execution](https://support.apple.com/en-az/guide/shortcuts/apdfbdbd7123/ios)

A candidate chain is: selected event → user-configured Shortcut → Suri App Intent → local assessment → permitted warning/escalation action. Users must knowingly configure/enable it. Do not assume the app can silently install the automation. If the event lacks readable content, return Insufficient content rather than classify a notification title as a complete message.

## Share to Suri

A Share Extension receives supported text and attachments supplied by the user. Screenshots shared through the system provide a dependable cross-app capture path. [Share Extension guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)

Keep the extension lightweight and cancelable. Validate OCR/classifier memory and runtime before putting the full pipeline in it. Richer main-app analysis is a fallback; do not assume every Share Extension can programmatically open the containing app or keep running after completion. Prototype the handoff. Manual Photos import and paste remain available.

## Carrier message filtering

IdentityLookup documents unknown-sender SMS/MMS handling, excluding contacts and iMessage. Associated-server deferral is system-mediated; the extension cannot use direct networking or write to containers shared with the main app. This prevents assuming a unified history or family escalation from every filter callback. [IdentityLookup](https://developer.apple.com/documentation/identitylookup/sms-and-mms-message-filtering)

Apple Support additionally mentions RCS. Keep that discrepancy explicit until tested. [Message filtering support](https://support.apple.com/en-lamr/guide/iphone/-iph203ab0be4/ios)

Use a suitable lightweight classifier and policy in a future filter extension. A large main-app language model is not automatically appropriate in this execution environment. Filtering uses system-defined categories; it is not a custom Messenger warning overlay.

## Family message transport

| Path | Requirements and constraints |
| --- | --- |
| Message composer | Prepares a message; user sends or cancels. Do not promise forced iMessage delivery. |
| Shortcuts Send Message | User-configured action; test consent, returned assessment, recipient parameters, confirmation, connectivity, and lock state. |
| Push to relative's app | Recipient needs installed app, verified pairing, notification permission, and connection. API acceptance is not receipt. |
| Backend SMS | Verified phone destination, provider setup, cost controls, consent, network access, and status callbacks. Not iMessage. |
| Critical Messaging | Capability and recipient authorization required; background-only sending, possible rate limits, SMS service required, program terms apply. Eligibility must be verified. |

[Message composer](https://developer.apple.com/documentation/messageui/mfmessagecomposeviewcontroller), [Critical SMS API](https://developer.apple.com/documentation/Messages/critical-messaging-api), [Program terms](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)

## Device spikes before architecture depends on automation

1. Record iPhone model, installed iOS build, SDK, and Apple Intelligence readiness.
2. Pass a screenshot through Share to Suri. Measure input availability, OCR, extension memory, and cancellation.
3. Pass an image/text through an App Intent from a manual Shortcut.
4. On supported OS, test a real Messenger notification with visible preview, hidden preview, truncation, grouped notifications, locked screen, and unlocked screen.
5. Test the Screenshot trigger, if present, without scanning all unrelated screenshots by default.
6. Test an incoming Messages automation separately from a Message Filter extension.
7. Test each selected alert transport with opted-in recipients, unavailable network, revocation, duplicates, and failure.

Record Observed, Unsupported, or Unresolved per case. A partial trigger is not a complete automated protection feature.

## Recommended fallback order

Share to Suri → manual photo/text import → manually invoked Shortcut → validated automatic event path. Never hide the fallback behind an account or cloud subscription.
