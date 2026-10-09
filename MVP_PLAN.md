# Suri MVP and implementation roadmap

## Locked implementation scope

The final interview selected SwiftUI, Vision, Qwen3 1.7B local analysis, correctable screenshot/text capture, Share to Suri, evidence-linked results, local history, settings/onboarding, and user-sent family help. Visuals use system SF Pro, bundled Solar icons, light-and-teal surfaces, and dark mode. Local AI remains the priority; optional OpenAI Online guidance shares only categories after opt-in. Raw cloud uploads, automatic alerts, and notification scanning are deferred.

The requested demo environment is the iPhone 17 Pro simulator. Runtime is llama.cpp CPU because MLX cannot perform simulator inference. The pinned Q4_K_M conversion is about 1.3 GB. Physical-device performance, actual Messages delivery, and live OpenAI calls remain separate validation gates. The user creates the showcase video with Claude.

## Build objective

Deliver one complete iPhone flow: **selected screenshot/text → local assessment → readable explanation → configured trusted-help action**. Optional cloud investigation adds source-backed evidence without becoming necessary for the local result.

Automatic checking and family messaging are user-requested goals. The first implementation must choose a validated capture/transport path rather than advertise all-app monitoring or silently substitute a simulated alert.

## Priorities

| Priority | Work |
| --- | --- |
| P0 | Branding, native shell, text/photo input, local OCR, correctable text, actual local inference, evidence validation, result UI |
| P0 | Offline completion, model/readiness failure state, trusted-contact configuration and sharing policy |
| P0 | One working user-controlled family-help path with honest status |
| P1 | Share to Suri with measured extension behavior; App Intent for a manually invoked Shortcut |
| P1 | One opted-in automated family transport if the required services/device behavior are validated |
| P1 | Optional cloud investigation with explicit payload preview and source-backed evidence |
| P2 | iOS 27 notification/screenshot automation after physical-device validation |
| P2 | Carrier-message filter as a separately scoped extension |
| Later | Safari integration, QR import, larger pattern packs, Mac companion, richer family case review |

If Share to Suri proves straightforward, move it into P0. If automation is the demo's central claim, perform its spike before feature work and only elevate it once its complete path succeeds.

## Phase 1 Establish feasibility

- Inspect the target device/OS, Xcode SDK, signing, and available local runtime.
- Test a short English and Filipino/Taglish input with the candidate local model.
- Test local OCR on a fresh synthetic conversation screenshot.
- Check Share Extension input, resource limits, and user cancellation.
- Prototype App Intent input/output, then version-specific event triggers if available.
- Compare alert transport options and choose one instead of implementing all of them.

**Gate:** A fresh local input yields a validated useful result. If it does not, resolve the model/input problem before UI breadth or cloud features.

## Phase 2 Complete the local app

- Build input selection and user correction.
- Add structured analysis, evidence validation, and bounded retry/cancellation.
- Add three assessment categories and a distinct analysis-failure state.
- Add downloaded verification material with source dates.
- Keep local records under a defined retention/deletion policy.
- Make the complete workflow usable without cloud credentials.

**Gate:** Disable network access and repeat with an unfamiliar screenshot and a legitimate message. No cached-result or hidden-cloud shortcut may masquerade as inference.

## Phase 3 Add trusted help

- Build contact confirmation and the consent policy.
- Implement a previewable manual help action.
- Add one automatic route only after recipient permission and transport behavior succeed.
- Enforce policy, payload minimization, deduplication, rate limiting, and actual delivery states.
- Test loss of connectivity, retries, cancellation, and consent revocation.

**Gate:** The configured recipient receives a real synthetic alert through the chosen transport; an unavailable transport stays pending/failed. If only manual sending works, document that scope.

## Phase 4 Add cloud evidence

- Resolve provider/data-source availability and applicable credential setup.
- Add a small authenticated gateway where needed; never embed cloud secrets in the app.
- Preview/minimize selected information before investigation.
- Return external sources, timestamps, query scope, and failure states.
- Preserve the local assessment when the cloud is unavailable or disagrees.

**Gate:** The cloud returns meaningful sourced evidence; fabricated reputation and unsourced model opinions must not be represented as verification.

## Phase 5 Polish and demonstrate

- Dynamic Type, VoiceOver, contrast, readable evidence, and straightforward recovery.
- Review copy for false certainty, shame, and confusing technical language.
- Run the validation plan, record actual limitations, and rehearse with listed teammates.
- Prepare public-repository setup instructions and all required disclosures.
- Record/post the demo and review the single submission before the deadline.

## Proposed module layout

```text
SuriApp/
  Features/Capture/
  Features/Assessment/
  Features/TrustedContacts/
  Features/Settings/
  Domain/
  Services/OCR/
  Services/LocalAnalysis/
  Services/CloudInvestigation/
  Services/Alerting/
  Persistence/
  Resources/ReferencePacks/
SuriShareExtension/
SuriIntents/
Tests/
```

This is a proposed structure, not an existing Xcode project. Separate targets/frameworks only when needed; avoid infrastructure that does not help the core path.

## Explicit deferrals

Do not train a large model from scratch, build a universal inbox, develop Android and Mac clients simultaneously, add broad antivirus features, implement a public social feed, or depend on special critical-SMS eligibility before a useful prototype exists. Do not equate a cloud outage with all network connectivity being unavailable; test both conditions separately.

## Completion criteria

- A selected screenshot/text can be checked locally on the demo device.
- Findings have real evidence and the user can correct extraction mistakes.
- No obvious warning signs is never shown as guaranteed Safe.
- The core flow works without a cloud account or provider connection.
- Family consent, selected recipients, payload, and transport states are inspectable.
- Automation claims match observed target-device behavior.
- External evidence is dated and source-linked.
- Model licenses, reused code/assets, and AI tools are disclosed.
- No secrets or real private data are in the public repository or video.

The historical roughly 20-hour estimate is not a current time budget. Recalculate remaining time against the organizer deadline before coding priorities are finalized.
