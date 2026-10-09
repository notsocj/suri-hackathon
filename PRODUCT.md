# Suri product brief

## Brand

- **Name:** Suri
- **Tagline:** Suri bago sorry.
- **Descriptive subtitle:** A scam-check companion for you and your family.
- **Share target:** Suri, with an action label such as Check with Suri.
- Name, trademark, domain, and App Store availability have not been checked.

## Problem

People receive messages that imitate trusted institutions, pressure them to act, request sensitive information, or propose financial transactions. They may need an understandable second opinion before clicking, disclosing information, installing software, or sending money.

For older adults, small text, technical explanations, and complicated reporting flows can make assistance difficult to obtain. Relatives can help, but the user should control when and what they share. These user-experience hypotheses need validation; age alone does not determine digital ability or susceptibility to scams.

Suri's job is to identify observable warning signs, explain the requested action, make uncertainty visible, and make trusted help easy to request. It does not identify a person's true identity from a screenshot or guarantee fraud prevention.

## Users

| User | Need |
| --- | --- |
| Philippine adult receiving a suspicious message | A quick check with understandable evidence and verification steps |
| Older adult who chooses additional assistance | A readable interface, spoken explanation, and simple trusted-contact flow |
| Trusted relative or helper | A minimal, consensually shared warning and a way to respond |

The primary product is the recipient's iPhone app. A family companion view or Mac app is a later option, not a required second platform for the first build.

## Philippine scope

Use realistic examples involving bank/e-wallet impersonation, courier fees, government-ID assistance, job or task offers, marketplace deposits, and requests from purported acquaintances. Currency, language, and local references should be understandable to Filipino users.

Filipino/English explanations and Taglish input quality are objectives to evaluate. Do not claim competitors cannot understand Taglish or that any chosen model handles it reliably before testing. Named institutions, numbers, reporting channels, and domains need source-backed, dated reference data. Do not imply partnership with government, banks, telcos, or messaging platforms.

## Core value

1. The user gives Suri selected content rather than granting unrestricted access to conversations.
2. Local processing identifies warning signs and produces a meaningful result without cloud AI.
3. The explanation points to the exact content supporting each finding.
4. The user can verify through independent channels or ask a configured trusted contact.
5. Optional cloud investigation adds external evidence and clearly states its source and freshness.

## Why local AI matters

Messages can contain private relationships, financial information, and identifiers. Local extraction and assessment allow a first check without uploading them. Processing already available content continues during weak connectivity, a cloud outage, or exhausted cloud quota. Remote delivery still needs an appropriate communication service.

Local does not automatically mean faster, more accurate, or secure. Measure latency and accuracy on the actual device. Keep the privacy claim scoped to the processing that actually stays on-device.

## Hybrid roles

| Local | Cloud |
| --- | --- |
| OCR of shared screenshots | Optional current domain/reputation evidence through selected services |
| Interpretation of requested actions and warning signs | Source-backed comparison with published scam campaigns/advisories |
| Evidence-linked explanation and uncertainty | Larger-context analysis of explicitly shared material |
| Downloaded verification guidance | Reviewed updates to reference or scam-pattern packs |
| Local case record and pending alert state | Online delivery of configured family alerts through a selected transport |

Synchronization and push delivery are ordinary services, not cloud AI. Cloud AI must provide an actual additional analytical capability. Reference updates should not silently install unreviewed model-generated block rules.

## Assessment language

Proposed categories are **Warning signs found**, **Needs verification**, and **No obvious warning signs found**. A failed or unsupported analysis has a separate **Could not complete check** state.

The last category is not proof of legitimacy. Avoid a green Safe badge, 100% scam claims, and numeric confidence percentages without calibration. Urgency, poor grammar, or an unfamiliar domain alone are insufficient to establish fraud.

## Family support

The user chooses contacts, verifies the destination, and enables a specific sharing policy. Automatic escalation should be limited, deduplicated, and understandable. A relative can respond or offer help, but a response does not override Suri's uncertainty or prove the message legitimate.

The default shared payload is a minimal warning summary. Screenshots, original text, sender details, and financial identifiers require deliberate additional sharing. See PRIVACY_AND_FAMILY_ALERTS.md.

## Scope boundaries

Suri is not a bank transaction blocker, identity authenticator, universal notification listener, emergency service, or automatic government-reporting service. It cannot give Messenger offline message delivery. The product should not become a broad cybersecurity suite during the hackathon.

## Success questions

- Can users complete a fresh local check without network calls?
- Do users understand the requested action, evidence, and what remains unverified?
- Does Suri avoid needless family alerts on ordinary messages?
- Can older users complete the flow with large text and assistive technology?
- Does cloud evidence add value without displacing confirmed local observations?
- Can a delivery failure be distinguished from a successfully received alert?

No adoption, accuracy, saved-time, or fraud-prevention benchmarks have been measured. Monetization is also undecided.
