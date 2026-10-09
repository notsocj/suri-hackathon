# Suri privacy and trusted family alerts

**Current implementation, 10 October 2026:** automatic notifications go only to the phone's owner. Their copy is fixed (heads-up, warning, finished, could not finish) and never includes the message, sender, code, link, or evidence. Automatic family delivery is **not implemented**. For automated checks Suri stores the normal result and evidence (if history is on), plus the time and stage of the last run and the time and category of the last check; never the full message. Check Copied Message reads the clipboard only when the user runs it, after the iOS paste prompt.

## Locked MVP policy

- Local OCR and Qwen analysis run first. Notification receipt and Wi-Fi availability do not prove current service connectivity and do not supply consent.
- Optional automatic Online guidance requires explicit opt-in, an allowed connection, complete validated input, a meaningful action category, and a configured authenticated gateway. Wi-Fi-only is the default; the network request itself disallows cellular when that setting is active.
- The only transmitted content fields are schemaVersion, an enumerated action, and enumerated warning patterns. Screenshots, text, evidence quotes, private codes, accounts, names, contacts, recipients, and URLs have no fields in the schema. Reject unknown fields rather than silently stripping them.
- Online guidance adds verification advice about a pattern; it does not independently inspect the original message. Its references come from a reviewed pack, not live reputation lookup. No excerpt-upload path is in this MVP.
- No offline upload queue. Provider failure preserves the local result. Changed input or revoked consent cancels pending work and discards stale responses; already transmitted requests cannot be recalled.
- Manual family help uses a fixed minimal draft for a user-configured recipient. The user sends or cancels in Messages. On the simulator, sending is unavailable and the app reports Not sent. A composer Sent callback is labeled Submitted to Messages, not delivery confirmed.
- User will configure OpenAI later in gateway/.env.local. That file is ignored. Only a gateway access token is entered in the app, stored in Keychain. No OpenAI secret belongs in a client bundle.

This later policy supersedes automatic-delivery and raw-excerpt proposals below. Retention is enforced on subsequent app/inbox access, not through a promise that an inactive app can run scheduled deletion.

## User control

Suri is a consensual assistance tool. The person using the checker controls capture, trusted contacts, automatic escalation, cloud sharing, and retention. A relative's desire to monitor someone does not supply consent. Large text and simple controls must support informed choice rather than hide it.

Configure recipients independently of scanned content. A malicious message saying Send this to another number must never change the configured recipient or alert policy.

## Trusted contact setup

1. The user chooses a person through a scoped picker or enters a destination.
2. Show the name/address/number for confirmation.
3. Verify the destination and establish recipient acceptance for the selected transport.
4. Explain what the relative receives and when.
5. Offer manual Ask my family first; automatic escalation is a separate opt-in.
6. Allow pause, contact removal, policy change, and revocation.

Destination verification does not establish that a person is trustworthy; the user makes that decision. Do not automatically pair every address-book contact or forward private messages to all family members.

## Proposed escalation policy

An automatic alert is eligible only when:

- The capture/analysis path is validated for the device.
- The result has adequate input quality and valid supporting evidence.
- The configured policy explicitly covers the finding.
- An accepted recipient and active consent version exist.
- The alert is not a duplicate and passes rate limits.
- The selected transport is permitted and available.

Urgency alone, OCR failure, unavailable cloud reputation, or an unknown sender alone should not trigger automatic family escalation. Prefer categorical findings with explicit policy rules to arbitrary model-generated percentages. A user can request help manually for any result.

## Minimal alert

Proposed default payload:

- Alert identifier and time.
- Which paired person needs assistance, disclosed only as configured.
- Requested-action category and a short warning summary.
- Whether the finding came from local content analysis or additional external evidence.
- A clear request to contact the person or review through the authorized app flow.

Do not include raw screenshots, entire conversations, OTPs, account numbers, or full sender details by default. Push previews should be generic enough for a locked phone. More evidence needs a separate user choice. Do not fabricate sender identity or state that a relative's account was hacked.

## Delivery states

Use distinct states such as Draft, Ready, Waiting for connection, Sending, Accepted by transport, Delivery confirmed, Failed, Canceled, and Reviewed by recipient. Not every transport exposes all states; display only the state actually established.

API success is not proof of delivery or reading. Retrying must preserve an idempotency key. Corrected input, revoked consent, or a canceled alert should invalidate queued work. Local revocation takes effect immediately; already dispatched work may need server confirmation and cannot necessarily be recalled.

An offline check can complete while a remote alert remains pending. If cellular SMS is available but internet is not, a validated authorized device-send path may behave differently from a backend transport. Do not claim this works without testing.

## Data objects

| Object | Suggested contents |
| --- | --- |
| Capture | ID, source type, selected content reference, capture time, OCR text/revision, input quality |
| Assessment | Validated findings, evidence, uncertainty, method/version, reference-pack version |
| TrustedContact | ID, user-chosen display name, verified transport destination, acceptance status |
| ConsentPolicy | User, recipient, purpose, content scope, trigger rule, version, enabled/revoked time |
| FamilyAlert | Assessment revision, recipient ID, consent version, minimized payload, stable identity, state |
| ExternalEvidence | Source URL/identifier, queried subject, observation time, retrieval time, scope |
| ReferencePack | Version, source list, issue dates, review status, validity/expiry policy |

Store destination tokens and secrets using appropriate platform protection. Protect local records with device data protection. Select retention limits deliberately; allow deletion and do not silently retain every message forever.

## Cloud request boundary

Before optional investigation, show a preview of the content leaving the device. Minimize names, identifiers, OTPs, and unrelated context. A URL may contain private tokens even when its domain looks public. Automated redaction is assistive and should not be advertised as infallible anonymization.

Local assessment must work without a cloud account. If automated server-based alerts are enabled, clearly disclose the minimum data transmitted under that policy. Server authentication and authorization must prevent a different account from reading cases or changing recipients.

Do not claim end-to-end encryption, no retention, or no model training by a provider until the implementation and provider terms establish those properties. Set explicit provider retention/training preferences where supported and document the actual behavior.

## Operational controls

- Apply per-user/per-contact alert rate limits and duplicate suppression.
- Keep the AI from directly dispatching messages or making network requests.
- Avoid automatic opening of URLs from screenshots, QR codes, or model output.
- Guard server URL investigation against private addresses, unsafe redirects, and unbounded content.
- Do not place API keys, tokens, real phone numbers, or real scam-victim screenshots in the public repository.
- Keep production diagnostics free of message bodies and private images by default.
- Give a helper a supportive role; do not let a family response become a guaranteed legitimacy verdict.

## Reporting and claims

An evidence bundle is a draft the user can review and share. Suri is not affiliated with CICC, BSP, banks, telcos, or police unless a partnership is actually established. Do not automatically submit reports or claim legal remedies, reimbursement eligibility, or official certification.

Privacy/legal review is an implementation requirement before public deployment, not a reason to leave the offline prototype unfinished. Use synthetic data for hackathon evaluation and the public demo.
