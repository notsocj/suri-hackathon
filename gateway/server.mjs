import { createServer } from 'node:http';
import { timingSafeEqual, createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { validatePayload, makeProviderRequest, validateResponse } from './policy.mjs';

const envPath = fileURLToPath(new URL('./.env.local', import.meta.url));
if (existsSync(envPath)) process.loadEnvFile(envPath);
const apiKey = process.env.OPENAI_API_KEY;
const accessToken = process.env.SURI_GATEWAY_TOKEN;
const model = process.env.OPENAI_MODEL || 'gpt-4.1-mini';
const port = Number(process.env.PORT || 8787);
const counters = new Map();
let inFlight = 0;

function authorized(value) {
  if (!accessToken || accessToken.length < 24 || typeof value !== 'string') return false;
  const expected = createHash('sha256').update('Bearer ' + accessToken).digest();
  const actual = createHash('sha256').update(value).digest();
  return timingSafeEqual(expected, actual);
}
function reply(response, status, value) {
  response.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
  response.end(JSON.stringify(value));
}
async function readBody(request) {
  let body = '';
  for await (const chunk of request) {
    body += chunk.toString('utf8');
    if (Buffer.byteLength(body) > 2048) throw new Error('oversized_payload');
  }
  return JSON.parse(body);
}
const server = createServer(async (request, response) => {
  if (request.method === 'GET' && request.url === '/health') return reply(response, 200, { configured: Boolean(apiKey && accessToken && accessToken.length >= 24) });
  if (request.method !== 'POST' || request.url !== '/guidance') return reply(response, 404, { error: 'not_found' });
  if (!authorized(request.headers.authorization)) return reply(response, 401, { error: 'unauthorized' });
  if (!apiKey) return reply(response, 503, { error: 'service_not_configured' });
  if (request.headers['content-type']?.split(';')[0] !== 'application/json') return reply(response, 415, { error: 'json_required' });
  const minute = Math.floor(Date.now() / 60000);
  for (const key of counters.keys()) if (key < minute - 1) counters.delete(key);
  if ((counters.get(minute) || 0) >= 10 || inFlight >= 2) return reply(response, 429, { error: 'rate_limited' });
  let payload;
  try { payload = validatePayload(await readBody(request)); }
  catch { return reply(response, 400, { error: 'invalid_category_payload' }); }
  counters.set(minute, (counters.get(minute) || 0) + 1);
  inFlight += 1;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  response.on('close', () => { if (!response.writableEnded) controller.abort(); });
  try {
    const upstream = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST', redirect: 'error', signal: controller.signal,
      headers: { 'Authorization': 'Bearer ' + apiKey, 'Content-Type': 'application/json' },
      body: JSON.stringify(makeProviderRequest(payload, model))
    });
    if (!upstream.ok) return reply(response, 502, { error: 'provider_unavailable' });
    const result = await upstream.json();
    if (result.status !== 'completed') throw new Error('incomplete_response');
    const text = (result.output || []).flatMap(item => item.type === 'message' ? item.content || [] : [])
      .filter(item => item.type === 'output_text').map(item => item.text).join('');
    const guidance = validateResponse(JSON.parse(text));
    return reply(response, 200, guidance);
  } catch {
    if (!response.destroyed) reply(response, 502, { error: 'guidance_unavailable' });
  } finally { clearTimeout(timeout); inFlight -= 1; }
});
server.requestTimeout = 20000;
server.headersTimeout = 10000;
server.listen(port, '127.0.0.1', () => {
  console.log(`Suri gateway listening on localhost:${port}. Live provider ${apiKey ? 'configured' : 'not configured'}.`);
});
