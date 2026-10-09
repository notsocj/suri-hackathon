# Suri

**Suri bago sorry.**

A native iPhone scam-check companion for Philippine users, with readable evidence and user-controlled trusted-family help. Selected content is assessed locally; optional Online guidance shares only fixed categories.

## Current implementation

- SwiftUI application and lightweight Share Extension in `Suri.xcodeproj`; deployment target iOS 18.
- Qwen3 1.7B Q4_K_M through llama.cpp b11527 CPU. The pinned GGUF download is **1.28 GB**. The model runs locally after setup; it is a general language model, not a validated specialist scam detector.
- Screenshot selection, Files import, Apple Vision OCR, editable extracted text, paste/type input, and selected-content Share to Suri intake.
- Opt-in **Check Message Locally** App Intent for a user-created Messages automation in Shortcuts, with private local warning notifications, a one-page in-app setup guide, a test action, and a Connected confirmation. iOS requires the user to create the trigger and to enter some Message Contains text (a common letter such as `a`). See [AUTOMATION_SETUP.md](AUTOMATION_SETUP.md).
- **Check Copied Message** App Shortcut for Messenger and other apps that no iOS automation can read: copy a message, run it from Shortcuts, Spotlight, Siri or the Action Button, and Suri opens and checks the copied text after iOS's paste prompt.
- Two local inference passes, grammar-constrained results, evidence/source validation, bounded retry, cancellation, and explicit analysis-failure states.
- Results show requested actions, quoted evidence, uncertainty, and independent verification guidance. No confidence percentages or guaranteed Safe verdict.
- Local history holds results/evidence, excludes full messages/screenshots, expires after 7 days, is pruned on next launch, and is limited to 50 records. Deletion controls are available.
- Trusted-contact setup and previewed user-sent Messages drafts. **Messages delivery is unavailable in the simulator**; drafts can be reviewed/copied and remain Not sent. Physical composer delivery is unverified.
- Optional authenticated Node gateway for OpenAI category-only Online guidance. **Live OpenAI calls remain unverified and credentials are not configured.** This is guidance from a dated reference pack, not live reputation investigation.
- SF Pro system typography with a lowercase SF Pro Rounded "suri bago sorry." wordmark, an original app icon (a message bubble with a lens), bundled Solar icons, capsule buttons, teal/light surfaces, dark mode, Dynamic Type, reduced-motion behavior, and spoken explanations. VoiceOver and full accessibility validation still need an explicit device walkthrough.

Development used the **iPhone 17 Pro simulator running iOS 26.5**, with Xcode 26.6 / Swift 6.3.3. MLX was initially evaluated and removed because its documented simulator limitation caused inference to crash.

### Tested on the user's iPhone (iOS 26.6.1, private TestFlight), 10 October 2026

Reported by the user from the phone, with screenshots:

- The app installs from TestFlight, the 1.28 GB model downloads (after the background-download fix in build 2), and manual local checks work.
- A Messages automation fired on real incoming SMS from a second phone and ran immediately. With build 7 the first incoming text was checked and produced a Suri warning; tapping it opened the result.
- On a second, longer text, Shortcuts reported "Check Message Locally could not run because an unknown error occurred" although Suri had saved the correct result. Build 8 answers Shortcuts early and finishes the check in the background; that fix is **verified only in the simulator so far**.

**Not tested on the phone:** build 8's early-answer fix, locked-screen runs, background memory use and timing, coverage of a single-letter Message Contains filter, Check Copied Message and the Action Button, the Messages composer for family help, and VoiceOver. SMS filtering, automatic family delivery, and live OpenAI connectivity are not implemented or not configured and must not be claimed.

## Run locally

Requires Apple Silicon, Xcode, CMake, Python 3, and sufficient storage for build artifacts plus the model. No cloud key is required to build or use local checks.

```sh
bash scripts/prepare_runtime.sh simulator
open Suri.xcodeproj
```

Select the **Suri** scheme and iPhone 17 Pro simulator, then Run. Simulator-only ad hoc entitlements enable real Keychain and App Group access without an Apple developer account; do not disable code signing for intake/storage checks. The project is already generated; Ruby's `xcodeproj` gem is only needed if regenerating it with `scripts/generate_project.rb`.

In Suri Settings, download the local model once. The app verifies the pinned model's SHA-256 checksum before marking it ready. The download uses a background session, so it continues if you lock the phone or switch apps, and it can be paused and resumed; do not force-quit Suri. On the simulator, pause/resume and a full verified download were exercised; on a physical iPhone this is not yet verified. Model download is setup traffic, never a message upload.

For development, `python3 scripts/prepare_model.py` prepares the same pinned model under ignored `.build/Models/Qwen3-1.7B-GGUF`. It does not install the model into an app automatically.

For a physical iPhone, first run `bash scripts/prepare_runtime.sh device`. Select your own Apple development team and compatible unique bundle/App Group identifiers for both targets. Signed Release builds are distributed to the user's private internal TestFlight group; see [TESTFLIGHT.md](TESTFLIGHT.md) for each build and what it was verified against. Physical-device findings are listed above.

## Optional OpenAI setup

Put credentials only in **`gateway/.env.local`**, copied from [gateway/.env.example](gateway/.env.example). Set `OPENAI_API_KEY` there. Never put that key in Swift, an Info.plist, an asset, or the iPhone settings.

The app accepts a separate gateway access token. The development gateway binds localhost; use `http://localhost:8787` in the simulator. Read [gateway/README.md](gateway/README.md) for setup, authentication, scope, and deployment limits. Public hosting is not configured. Automatic guidance is off until the user explicitly enables category-only sharing.

## Validation

```sh
swift test --scratch-path .build/core
node --test gateway/policy.test.mjs
xcodebuild -project Suri.xcodeproj -scheme Suri -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- test
```

24 core checks cover fabricated evidence, ambiguous input, protective code advice, source spans, consent changes, private-payload exclusion, invalid recipients, private notification copy, sender-instead-of-message input, and duplicate/concurrent automation work. 10 iOS integration checks cover OCR negation/time, invalid images, secure local storage, Share intake, opt-in enforcement, a real local run of the Shortcuts action, a slow check that answers Shortcuts early and still finishes, and the copied-message request. Simulator UI checks exercise fresh local Tagalog/English inference and untrusted instructions. Small synthetic checks are development gates, **not an accuracy benchmark**. Invalid model evidence produces Could not complete check rather than a fabricated result.

## What runs locally, and what needs a connection

| Runs on the phone, offline | Needs a connection |
| --- | --- |
| OCR of screenshots (Apple Vision) | One-time 1.28 GB model download from Hugging Face |
| Both Qwen3 inference passes and evidence validation | Receiving the SMS itself (carrier) |
| Results, history, family-help drafts | Sending a family-help text (the user taps Send in Messages) |
| Shortcuts action, warning notifications, copied-message check | Optional Online guidance via the user's own gateway and OpenAI (off by default; category-only) |

**Why local AI:** the messages Suri checks are exactly the ones that contain OTPs, account numbers and personal details. Checking them on the phone means none of that text is uploaded, checks keep working with no signal or data, and an automatic check of every incoming text costs nothing per message.

## Product and engineering context

| Document | Purpose |
| --- | --- |
| [DECISIONS.md](DECISIONS.md) | Locked choices, runtime correction, unresolved device/provider gates |
| [PRODUCT.md](PRODUCT.md) | Audience, positioning, scope |
| [UX.md](UX.md) | Flow and accessibility requirements |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Implemented boundaries and future proposals |
| [PRIVACY_AND_FAMILY_ALERTS.md](PRIVACY_AND_FAMILY_ALERTS.md) | Consent, category-only payload, manual help, retention |
| [IOS_CAPABILITIES.md](IOS_CAPABILITIES.md) | Platform constraints; documented does not mean tested |
| [MVP_PLAN.md](MVP_PLAN.md) | Locked scope and acceptance gates |
| [DEMO_AND_VALIDATION.md](DEMO_AND_VALIDATION.md) | Honest offline demonstration and checks |
| [RESEARCH.md](RESEARCH.md) | Dated source register |
| [HACKATHON.md](HACKATHON.md) | Deadline and submission rules supplied by the user |
| [AGENTS.md](AGENTS.md) | Instructions for development |
| [fixtures/scenarios.json](fixtures/scenarios.json) | Synthetic seed cases, not measured performance |

## Disclosures

App implementation was created during the build session spanning 9–10 October 2026 with the AI coding tools **Codex** and **Claude Code**. Codex built the initial app, local inference, gateway, Shortcuts action and notifications, and TestFlight builds 1–4. Claude Code did the interface redesign and wordmark, the background model download, the Message automation setup guide and fixes, Check Copied Message, and TestFlight builds 5 onward. Reused components include SwiftUI/Vision, llama.cpp (MIT), Qwen3 weights (Apache 2.0), and Solar icons by 480 Design (CC BY 4.0). See bundled `THIRD_PARTY_NOTICES.txt`. The user creates the showcase video with Claude and will disclose its reused components/tools separately.

No outside people were contacted, no live family-help messages were sent, and no hackathon submission or public App Store release was made. The user authorized a private TestFlight demo; its status is recorded in [TESTFLIGHT.md](TESTFLIGHT.md). The user-supplied deadline remains **10 October 2026, 10:00 AM Philippine time**; other publication/submission requires explicit authorization.
