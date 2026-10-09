export const actions = Object.freeze(['share_code', 'pay_upfront', 'send_money', 'change_destination', 'share_personal_details', 'open_link', 'install_software', 'ordinary']);
export const patterns = Object.freeze(['code_disclosure', 'upfront_payment', 'changed_destination', 'sensitive_details', 'secrecy', 'time_pressure', 'remote_access']);

export function validatePayload(value) {
  if (!value || Array.isArray(value) || typeof value !== 'object') throw new Error('invalid_payload');
  const keys = Object.keys(value).sort();
  if (JSON.stringify(keys) !== JSON.stringify(['action', 'patterns', 'schemaVersion'])) throw new Error('invalid_payload');
  if (value.schemaVersion !== 1 || !actions.includes(value.action)) throw new Error('invalid_payload');
  if (!Array.isArray(value.patterns) || value.patterns.length > 5 || value.patterns.some(p => !patterns.includes(p))) throw new Error('invalid_payload');
  if (new Set(value.patterns).size !== value.patterns.length) throw new Error('invalid_payload');
  return { schemaVersion: 1, action: value.action, patterns: [...value.patterns].sort() };
}

export const references = Object.freeze([
  { id: 'bsp-fraud', title: 'BSP: Protect yourself from fraud and scams', reviewedOn: '2026-10-09',
    url: 'https://www.bsp.gov.ph/Media_and_Research/Primers%20Faqs/Protect_yourself_from_Fraud_and_Scam.pdf',
    guidance: 'Keep verification codes private. Verify requests using independently obtained official channels. Pause before making an unexpected payment.' },
  { id: 'psa-phishing', title: 'PSA: Messaging-app phishing advisory', reviewedOn: '2026-10-09',
    url: 'https://psa.gov.ph/system/files/philsys/Public%20Advisory%20on%20Phishing%20Scams%20and%20Offers%20of%20Assistance%20in%20Downloading%20the%20Digital%20National%20ID%20via%20Messaging%20Apps.pdf',
    guidance: 'Verify offers of digital-ID assistance through official channels rather than sharing personal details or verification codes in a chat.' }
]);

export function makeProviderRequest(payload, model) {
  const safe = validatePayload(payload);
  return {
    model, store: false, max_output_tokens: 300,
    instructions: 'Give concise, supportive verification guidance in English for a Philippine user. You receive only action/pattern categories, never an original message. Do not classify a sender as fraudulent or safe, claim current website reputation, invent identity, give phone numbers, or say the original message was verified. Ground your answer only in the supplied reference summaries. Do not add links. Return 2-3 practical sentences and applicable reference IDs.',
    input: JSON.stringify({ categories: safe, referenceSummaries: references.map(({ id, guidance }) => ({ id, guidance })) }),
    text: { format: { type: 'json_schema', name: 'pattern_guidance', strict: true,
      schema: { type: 'object', properties: { guidance: { type: 'string' }, referenceIDs: { type: 'array', items: { type: 'string', enum: references.map(r => r.id) } } }, required: ['guidance', 'referenceIDs'], additionalProperties: false } } }
  };
}

export function validateResponse(value) {
  if (!value || typeof value.guidance !== 'string' || value.guidance.length < 1 || value.guidance.length > 1500 || /https?:\/\/|\d{6,}/i.test(value.guidance)) throw new Error('invalid_response');
  if (!Array.isArray(value.referenceIDs) || value.referenceIDs.length < 1 || value.referenceIDs.length > 2 || value.referenceIDs.some(id => !references.some(r => r.id === id))) throw new Error('invalid_response');
  return { guidance: value.guidance, referenceIDs: [...new Set(value.referenceIDs)], scope: 'pattern_guidance', generatedAt: new Date().toISOString() };
}
