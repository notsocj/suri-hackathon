# Suri user experience

## Interface direction

Use a calm, minimal native interface. Lead with one task: **Check a message**. Avoid a dashboard full of scores, constant alarm language, or technical networking details. Preserve the tagline **Suri bago sorry.**

Large Dynamic Type, clear contrast, VoiceOver, generous touch targets, visible text labels, and predictable navigation are product requirements. Meaning must not rely on color, sound, or haptics alone. Spoken explanations should use installed voices/assets and remain optional.

## Onboarding

1. Explain: Suri checks selected content for warning signs and helps the user verify or ask family.
2. Show what stays local and what optional online actions transmit.
3. Check local-model availability. Do not falsely mark setup complete if the model is not ready.
4. Demonstrate a synthetic screenshot, with a clearly labeled example result.
5. Offer trusted-contact setup as an optional separate step.
6. Offer shortcut/automation setup only for capabilities verified on this device.

The user can check a message without pairing family or creating a cloud account. Contacts, Photos, camera, microphone, and notifications should be requested only when a chosen feature needs them. Do not request an entire contact list merely to choose one relative.

## Home screen

- Primary: Check a message.
- Inputs: Share to Suri, choose screenshot, paste text, or scan a QR when implemented.
- Secondary: Recent checks, trusted contacts, settings.
- Show relevant model/setup availability without implying the app is continuously monitoring all chats.

## Share to Suri flow

Screenshot → Share → Suri → local extraction → correct/crop if needed → assessment → next action.

Where an app does not expose text to the system Share Sheet, accept a user-taken screenshot. Do not promise a direct integration with every messaging app.

Let the user narrow a screenshot to the relevant message before cloud sharing. OCR should be inspectable and correctable. If a URL, amount, negation, or requested action is unclear, ask for a better image or correction rather than treating uncertain OCR as reliable evidence.

## Result screen

Display these elements in this order:

1. Plain status: Warning signs found, Needs verification, or No obvious warning signs found.
2. What the message asks the user to do.
3. A small number of warning signs with the exact supporting text.
4. What remains unverified, such as sender identity or current website reputation.
5. One useful verification step.
6. Ask my family and optional Investigate online actions.

Example with synthetic data:

> **Warning signs found**
>
> This message asks you to disclose an OTP. It also pressures you to act quickly. Suri cannot confirm who sent it.
>
> Verify using your institution's independently obtained official channel.

A Filipino explanation can be displayed alongside English after language-quality validation. Proposed action labels include **Suriin**, **Ipa-check sa pamilya**, and **Basahin ang paliwanag**. These are draft copy, not final translations.

## Asking family

For manual sharing, preview the recipient and payload before the user sends. For an opted-in automatic policy, show which contact is configured, what gets shared, and the actual delivery state. A family response can be **I'll contact you**, **Reviewed**, or a text note; it must not become a Safe verdict.

Manual help remains available even when the model finds no obvious warning signs. Automatic escalation should not trigger merely because OCR or the model failed.

## Automatic check experience

When a validated automation supplies content, identify that source and its limitations. A notification preview may be incomplete. Avoid repeated alerts for updates to the same notification. A user should be able to pause automatic checking and family escalation independently.

Do not obstruct another app or imply Suri blocked a payment. The alert encourages verification and contact; it is not a transaction-control feature.

## Offline and failure states

| Condition | User-facing behavior |
| --- | --- |
| Cloud unavailable | Show the complete local result; online evidence is Not checked online |
| Alert has no connection | Waiting for connection, with cancel option |
| Alert transport failed | Couldn't send; offer retry or direct contact |
| Model not ready/unsupported | Could not complete check; explain setup or manual-help path |
| OCR insufficient | Ask for correction or a clearer image |
| No readable preview | Not enough message content to check |
| Reference pack outdated | Show its date; do not imply fresh external verification |
| Contact consent revoked | Stop future transmission; keep user in control of local record |

## Accessibility validation

Run the full flow with large text, VoiceOver, reduced motion, and one-handed interaction. Check that evidence highlights and recipient previews remain readable. Ask a listed teammate to follow the flow without coaching during the hackathon. Later research with older users should test comprehension and autonomy, not just visual preference.
