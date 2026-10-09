# Suri

**Suri bago sorry.**

A native iPhone scam-check companion for Philippine users, with readable evidence and user-controlled trusted-family help. Selected content is assessed locally; optional Online guidance shares only fixed categories.

## Current implementation

- SwiftUI application and lightweight Share Extension in `Suri.xcodeproj`; deployment target iOS 18.
- Qwen3 1.7B Q4_K_M through llama.cpp b11527 CPU. The pinned GGUF download is **1.28 GB**. The model runs locally after setup; it is a general language model, not a validated specialist scam detector.
- Screenshot selection, Files import, Apple Vision OCR, editable extracted text, paste/type input, and selected-content Share to Suri intake.
- Two local inference passes, grammar-constrained results, evidence/source validation, bounded retry, cancellation, and explicit analysis-failure states.
- Results show requested actions, quoted evidence, uncertainty, and independent verification guidance. No confidence percentages or guaranteed Safe verdict.
- Local history holds results/evidence, excludes full messages/screenshots, expires after 7 days, is pruned on next launch, and is limited to 50 records. Deletion controls are available.
- Trusted-contact setup and previewed user-sent Messages drafts. **Messages delivery is unavailable in the simulator**; drafts can be reviewed/copied and remain Not sent. Physical composer delivery is unverified.
- Optional authenticated Node gateway for OpenAI category-only Online guidance. **Live OpenAI calls remain unverified and credentials are not configured.** This is guidance from a dated reference pack, not live reputation investigation.
- SF Pro system typography, bundled Solar icons, teal/light surfaces, dark mode, Dynamic Type, reduced-motion behavior, and spoken explanations. VoiceOver and full accessibility validation still need an explicit device walkthrough.

The requested development/demo environment is the **iPhone 17 Pro simulator running iOS 26.5**, with Xcode 26.6 / Swift 6.3.3. Physical iPhone performance, notification automation, SMS filtering, automatic family delivery, and actual provider connectivity must not be claimed as tested. MLX was initially evaluated and removed because its documented simulator limitation caused inference to crash.

## Run locally

Requires Apple Silicon, Xcode, CMake, Python 3, and sufficient storage for build artifacts plus the model. No cloud key is required to build or use local checks.

```sh
bash scripts/prepare_runtime.sh simulator
open Suri.xcodeproj
```

Select the **Suri** scheme and iPhone 17 Pro simulator, then Run. Simulator-only ad hoc entitlements enable real Keychain and App Group access without an Apple developer account; do not disable code signing for intake/storage checks. The project is already generated; Ruby's `xcodeproj` gem is only needed if regenerating it with `scripts/generate_project.rb`.

In Suri Settings, download the local model once. The app verifies the pinned model's SHA-256 checksum before marking it ready. Keep the app open during the download. Model download is setup traffic, never a message upload.

For development, `python3 scripts/prepare_model.py` prepares the same pinned model under ignored `.build/Models/Qwen3-1.7B-GGUF`. It does not install the model into an app automatically.

For a physical iPhone, first run `bash scripts/prepare_runtime.sh device`. Select your own Apple development team and compatible unique bundle/App Group identifiers for both targets. A signed iPhone Release archive and TestFlight IPA have been prepared for the user's team; see [TESTFLIGHT.md](TESTFLIGHT.md) for current distribution status. Physical-device installation, inference performance, and delivery remain unverified.

## Optional OpenAI setup

Put credentials only in **`gateway/.env.local`**, copied from [gateway/.env.example](gateway/.env.example). Set `OPENAI_API_KEY` there. Never put that key in Swift, an Info.plist, an asset, or the iPhone settings.

The app accepts a separate gateway access token. The development gateway binds localhost; use `http://localhost:8787` in the simulator. Read [gateway/README.md](gateway/README.md) for setup, authentication, scope, and deployment limits. Public hosting is not configured. Automatic guidance is off until the user explicitly enables category-only sharing.

## Validation

```sh
swift test --scratch-path .build/core
node --test gateway/policy.test.mjs
xcodebuild -project Suri.xcodeproj -scheme Suri -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .build/DerivedData CODE_SIGN_IDENTITY=- test
```

Core checks cover fabricated evidence, ambiguous input, protective code advice, source spans, consent changes, private-payload exclusion, and invalid recipients. iOS integration checks cover OCR negation/time, invalid images, secure local storage, and Share intake. Simulator UI checks exercise fresh local Tagalog/English inference and untrusted instructions. Small synthetic checks are development gates, **not an accuracy benchmark**. Invalid model evidence produces Could not complete check rather than a fabricated result.

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

App implementation was created during the build session spanning 9–10 October 2026 with Codex. Reused components include SwiftUI/Vision, llama.cpp (MIT), Qwen3 weights (Apache 2.0), and Solar icons by 480 Design (CC BY 4.0). See bundled `THIRD_PARTY_NOTICES.txt`. The user creates the showcase video with Claude and will disclose its reused components/tools separately.

No outside people were contacted, no live family-help messages were sent, and no hackathon submission or public App Store release was made. The user authorized a private TestFlight demo; its status is recorded in [TESTFLIGHT.md](TESTFLIGHT.md). The user-supplied deadline remains **10 October 2026, 10:00 AM Philippine time**; other publication/submission requires explicit authorization.
