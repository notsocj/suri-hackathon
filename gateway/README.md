# Suri Online guidance gateway

Node.js 24 or newer. No npm dependencies. This gateway is implemented and needs the user's own OpenAI credentials to make live calls.

1. Copy `.env.example` to `.env.local` in this directory.
2. Put the OpenAI key in `OPENAI_API_KEY`. It is server-only; never enter it in the iPhone app.
3. Set `SURI_GATEWAY_TOKEN` to a random value of at least 24 characters.
4. Run `node gateway/server.mjs` from the project root.
5. In simulator Suri Settings, enter `http://localhost:8787` as the gateway URL and the gateway token as its access token. Enable automatic guidance only after reading the consent explanation. The default is Wi-Fi only.

Run `node --test gateway/policy.test.mjs` for local schema/privacy tests without credentials or provider requests.

The server binds localhost for the simulator demo. Public hosting is not configured or authorized. Any later deployment must use HTTPS, per-user authentication, provider spend limits, appropriate retention settings, and operational review; the demo's shared token is not a production family-account system.

Only schemaVersion, fixed action values, and fixed warning-pattern values are accepted. Unknown fields are rejected. Screenshots, source text, quotes, OTPs, identifiers, contacts, and URLs cannot be sent through this endpoint. Incoming request bodies and credentials are not logged. A fixed 15-second provider timeout and rate/concurrency limits constrain cost. No submitted URL is fetched.

The provider receives category data and curated reference summaries. This is online guidance, not live reputation investigation, verification of the original message, or a cloud scam verdict. References are a dated reviewed pack, not live retrieval. `store: false` disables Responses storage; it does not establish zero retention under all provider policies.

API details checked against the official [Structured Outputs documentation](https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=responses). The default model is configurable via `OPENAI_MODEL`.
