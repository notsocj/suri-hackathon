# Suri demo and validation


## Current observed validation

**Update, 10 October 2026 (morning).** Simulator checks now total 27 core, 10 iOS integration, 6 gateway, and 4 UI tests. The user has also tested private TestFlight builds on their iPhone (iOS 26.6.1): the model downloads, manual checks work, and a Messages automation fired on real SMS from a second phone; with build 7 the first text produced a Suri warning that opened the result, and a second, longer text made Shortcuts report "unknown error" although Suri saved the correct result. Builds 8–10 add an early answer to Shortcuts, Check Copied Message, and an instant heads-up. With build 10 the user reports that SMS automation with the heads-up, Check Copied Message from the Action Button, and Ask my family all work on the phone. See [README.md](README.md) and [AUTOMATION_SETUP.md](AUTOMATION_SETUP.md). The bullets below are the original 9 October record.

- Xcode 26.6 / Swift 6.3.3; iPhone 17 Pro simulator, iOS 26.5. Signed native app and Share Extension compile successfully.
- 27 deterministic core checks pass, including parameterized variants: schema/evidence, negation, OCR source spans, consent, recipient validation, private-field exclusion, narrow two-pass code-intent reconciliation, private notification copy, duplicate/concurrent automation work, and which texts get the heads-up.
- Six gateway policy tests pass without a provider key or live API request.
- Ten iOS integration tests pass: readable OCR preserves negation/time, blank/invalid images are rejected, Keychain round-trip works, App Group intake consumes the selected text locally, opt-in is enforced, the Shortcuts action runs a real local check, a slow check answers Shortcuts early and still finishes, and the copied-message request works.
- Four simulator UI tests pass using actual Qwen inference: English code delivery, legitimate appointment urgency, Tagalog code disclosure with evidence, and untrusted instructions that cannot produce a clean result or alter a recipient. The injection test permits explicit failure when evidence cannot be validated; it is not proof every injection is detected successfully.
- Screenshot selection and OCR text were inspected in the running app using a synthetic conversation image.
- Early single-pass attempts produced false positives on code delivery and failed evidence validation. The implemented pipeline now separates code-handling comprehension from the full assessment, checks source spans, and allows one bounded local retry. The tests were used during development; they are not an independent accuracy benchmark.
- Simulator local processing observed about 5–15 seconds in early checks; final two-pass/retry timing varies and is recorded per result. These are Mac-hosted simulator measurements, not iPhone performance figures.
- Checks ran in the simulator and on the user's iPhone through TestFlight (see README). Optional cloud guidance was not used for any result recorded here; local results never depend on it.

Use the synthetic image in fixtures/synthetic-message.png for capture demonstrations. State that it is synthetic, and say whether the demo is running in the simulator or on the iPhone. Do not claim model calibration, live domain reputation, or confirmed delivery.

## Demonstration claim

Suri can analyze fresh, selected message content locally and help a Philippine user understand warning signs or ask a trusted relative. Cloud investigation and remote delivery are separately demonstrated capabilities, not hidden dependencies.

## Suggested one minute video

| Segment | Show |
| --- | --- |
| Opening | Suri name/tagline and one everyday suspicious-message situation |
| Capture | Share a synthetic conversation screenshot to Suri or import it |
| Offline check | Disable network access and analyze fresh content with the installed local model |
| Explanation | Requested action, exact evidence, uncertainty, and a practical verification step |
| Family support | Show opt-in contact/payload; demonstrate the selected actual transport or its honest pending state |
| Closing | Reconnect for optional sourced cloud evidence; summarize the observed local advantage |

This is a script, not measured timing. Keep the video near the user's requested one-minute goal and rehearse actual device performance.

## Live demo

Use unfamiliar synthetic messages from listed teammates. Include a legitimate urgent message and an obvious credential/payment scam. Demonstrate restraint as well as detection. Show OCR correction, recipient consent, and an unavailable-cloud result. If a Notification trigger is validated, show an actual event on the target OS; otherwise demonstrate the Share to Suri path and state the automation limit.

Use an actual family alert only with listed teammates who agreed to receive it. No real victim information, OTPs, live malicious links, or financial transactions are necessary.

## Functional checks

- Share/paste/import receives the intended content and supports canceling.
- OCR preserves negation, amounts, sender labels, and URLs well enough for analysis; unclear fields require correction.
- The app distinguishes partial notification previews from complete text.
- Evidence quotes/spans exist in the analyzed revision.
- Correction invalidates old results and unsubmitted alerts.
- Model output cannot change recipients, cloud-sharing scope, or alert policy.
- Suspicious links are parsed without being automatically opened.
- Failed inference is not converted into a No obvious warning signs result.
- Local checking is available when cloud authentication, quota, or server connectivity fails.

## Detection evaluation

Use fixtures/scenarios.json as synthetic seed material, not a scientific benchmark. The review label is a target interpretation, not proof of a model's accuracy. Create a held-out set containing new wording, layouts, and mixed-language examples. Keep test wording out of the prompts used to tune behavior where possible.

Include scams and legitimate messages: OTP delivery versus OTP disclosure requests, real time-sensitive announcements, ordinary promotions, marketplace arrangements, friend requests, and institutional advisories. Record false positives, missed warning signs, unsupported cases, and human comprehension of explanations. A risk category should not be treated as a proven fraud label.

Report actual sample size and conditions. Do not claim 99% accuracy, fraud prevention, or calibrated confidence without evidence. A small synthetic evaluation cannot establish real-world performance for older adults or all Philippine scam campaigns.

## Privacy and alert checks

- First analysis makes no unapproved remote request.
- Payload preview matches what is transmitted.
- Raw screenshot/OTP/contact data do not appear in logs or default alerts.
- Recipient identity is configured outside model content.
- Opt-out stops new escalation and cancels local queued work.
- Repeated capture and retries do not send duplicate alerts.
- No connection displays Waiting for connection rather than Sent.
- Server/API acceptance and confirmed delivery are different states.
- Family response records assistance, not guaranteed legitimacy.
- One family/account cannot read another family's records.

## Device and accessibility checks

Record iPhone model, iOS build, local model/version, SDK, input length, and stage latency. Test warm and cold inference, long text, canceled analysis, low-quality screenshots, and unavailable model assets. For automation, include locked/unlocked phone, previews on/off, truncated/grouped notifications, and revoked permissions.

Run large Dynamic Type and VoiceOver through capture, correction, result, and contact setup. Assess whether a person understands the explanation and next action, not just whether the screen looks polished.

## Offline and online distinctions

| State | Expected behavior |
| --- | --- |
| Internet available, cloud AI down | Local check completes; online investigation unavailable |
| Airplane mode | Selected content can be analyzed locally if assets are installed |
| Internet unavailable, cellular SMS available | Only a validated authorized device-send route may work; backend transport cannot assume connectivity |
| Online investigation succeeds | Add sourced external evidence without overwriting local observations |
| No negative domain reputation found | Keep uncertainty; no green Safe guarantee |

## Honest limitations to state

The selected model may have language, context, memory, or false-positive limitations. Screenshots may omit sender metadata or preceding messages. Reference packs can be stale. Remote alert delivery is conditional. Suri is a support tool, not identity verification, guaranteed protection, or an emergency service.
