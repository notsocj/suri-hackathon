# Suri decisions and open questions

## Local automation implementation — 10 October 2026

After reporting successful manual checks, the user requested incoming-message automation and owner notifications, including other chat apps where possible. The phone's reported OS is **iOS 26.6.1**. The app now exposes an opt-in local-only Shortcuts action and private warning notifications. A user-created Messages trigger must supply the body; arbitrary Messenger/other-app notification access is unavailable through normal notification APIs on this OS. The app does not silently create triggers or claim every incoming message is covered. Notification copy uses Warning signs found rather than asserting fraud. No automated family delivery or cloud message upload was added. See [AUTOMATION_SETUP.md](AUTOMATION_SETUP.md) for setup and explicit verification limits.

## Private TestFlight setup — 10 October 2026

The user authorized a private TestFlight demo and supplied App Store Connect API credentials. The account is authenticated through macOS Keychain; secrets remain outside the repository. Apple rejected the listing name Suri as already used. The user's final selection is **Suri: Scam Check**, with **Suri bago sorry.** as its subtitle; the installed app continues to display Suri. Both bundle IDs and their shared App Group are registered. A distribution signing certificate and internal Suri Demo group are created. Archive/export/upload status is tracked in [TESTFLIGHT.md](TESTFLIGHT.md); account setup alone does not establish availability or physical-device validation.

## Locked build direction — 9 October 2026

The user finalized these choices in the implementation interview:

- Native Swift + SwiftUI iPhone application; Apple Vision for local OCR.
- Evaluate Qwen3 1.7B at 4-bit first for local English/Filipino/Taglish analysis. Actual accuracy, latency, memory, and device compatibility remain unverified until tested. Apple Foundation Models is a possible later second engine.
- Screenshot import, paste, correctable OCR, Share to Suri, evidence-linked results, history, family setup, onboarding, and settings form the initial app.
- Family help is a previewed message to a configured recipient that the user sends. Automatic family delivery is deferred.
- SF Pro using system text styles, bundled Solar Outline/Bold icons, warm light surfaces, deep teal actions, matching dark mode, Dynamic Type, VoiceOver, and reduced motion. Apply frontend-design and apple-design principles in native SwiftUI.
- Prioritize fresh offline analysis. Optional OpenAI Online guidance may receive only a strict category-only payload after opt-in; never raw screenshots/text, evidence quotes, OTPs, accounts, names, contacts, or URLs. This is guidance about a pattern, not independent verification of the original message.
- Connectivity is an execution condition, not sharing permission. A notification is not proof of current internet access. Preserve the local result on network/provider failure. No automatic upload queue when offline.
- OpenAI credentials will be configured by the user later in gateway/.env.local, exclusively on the server. No live OpenAI integration has been verified.
- User owns showcase-video creation with Claude. Implementation does not authorize publishing or submission.

Runtime correction during implementation: MLX officially does not support iOS Simulator inference and crashed during the first real test. The user requested the iPhone 17 Pro simulator. The build therefore uses llama.cpp b11527 CPU with the same Qwen3 1.7B model, in pinned Q4_K_M GGUF format. The ggml-org conversion is 1,282,439,264 bytes (about 1.3 GB), larger than the previously discussed 930 MB MLX package. No model accuracy or device performance is inferred from this runtime change.

These later choices supersede conflicting proposed defaults below. Device testing and implementation status must still be reported honestly.

## Accepted user direction

| Decision | Context |
| --- | --- |
| Name is Suri | User selected the name after naming exploration |
| Tagline is Suri bago sorry. | User explicitly confirmed this wording |
| Focus first on the Philippines | User requested Philippine scope |
| Help older adults and trusted relatives | User requested accessibility and family escalation |
| Local and cloud AI cooperate | Core offline usefulness is part of the hackathon challenge |
| Share to Suri for screenshots | User proposed this as a preferred interaction |
| Explore automated checking and message delivery | Desired features, with implementation dependent on platform validation |
| Apple application | Most recent concrete target is iPhone; Mac was discussed as a possible platform |
| Available hardware | Mac with Xcode and iPhone 17 |

## Proposed defaults rather than settled choices

- Native SwiftUI iPhone app.
- Screenshot/text checking as the reliable initial input path.
- On-device OCR plus an evaluated local text classifier or compact language model.
- A main-app service for richer explanations, with lightweight extension behavior.
- Minimal, opt-in family alerts; cloud push/backend SMS as candidate automated transports.
- User-configured Shortcuts and App Intents for capture and conditional escalation.
- A small cloud gateway for optional investigation and alerts, keeping provider secrets out of the client.

These can change based on evidence or later user preferences. No provider or model is selected by this package.

## Corrections to preserve

### Notification capture

An ordinary app cannot read all other apps' notifications through its own notification APIs. However, the earlier blanket conclusion that no iPhone automation route exists was too broad. Apple's **iOS 27 Shortcuts guide** documents Notification and Screenshot triggers. This creates a possible user-configured bridge, not a verified all-app background scanner. The iOS 26 event-trigger page does not list these triggers.

### Message delivery

A normal app's message composer requires a user send action. That is different from a user-configured Shortcuts Send Message action, an online backend sending SMS/push, and Apple's restricted critical-SMS mechanism. None should be described as an unrestricted app-controlled iMessage API.

### Competitors

Screenshot checking, automatic SMS filtering, local processing, and family features already exist somewhere in the market. Bitdefender documents notification/chat scanning on Android. Suri's proposed combined experience must be demonstrated and evaluated; it is not established as a market first.

## Required before implementation choices

| Open question | Why it matters |
| --- | --- |
| Exact installed iOS version | Determines automation paths and APIs |
| Apple Intelligence enabled and model ready | Eligible hardware alone does not guarantee model availability |
| Xcode/SDK version and signing capability | Determines build and extension support |
| Local model and licensed artifacts | Determines supported input, memory, inference, and disclosures |
| Filipino/Taglish quality | Must be tested rather than inferred from language marketing |
| Cloud provider and credentials | No live provider or API key is configured |
| Cloud reputation/reference source | Availability, freshness, licensing, and actual evidence are unresolved |
| Alert destination and transport | Push requires recipient app/authentication; backend SMS has provider costs; Shortcuts needs setup |
| Notification automation payload and lock-state behavior | Must be tested with actual Messenger/Facebook notifications |
| False-positive and escalation policy | The model must not create noisy or privacy-invasive family alerts |
| Team names, repository, demo device setup | Required for the eventual submission |

## Device findings to record

For every spike record the device, iOS build, SDK, permissions, locked/unlocked state, input type, observed result, latency, and limitation. A screenshot from a guide is not evidence that the user's phone supports the behavior.

## Earlier context that is outside current scope

The conversation explored El Niño assistance, farmers, barangay coordination, rider support, developer tools, and multi-item photo listing apps. Those ideas informed the search for a useful local/cloud product. They are not requirements for Suri. Do not add water tracking, farming guidance, API mocking, garage listings, or a universal household assistant to the MVP.

## Working constraints

The user earlier reported roughly 20 build hours, with one developer and three other teammates. That was a historical estimate, not the remaining time now. Deadline details are in HACKATHON.md. Treat this as a small-team build and select one complete local workflow plus one validated family-help route.
