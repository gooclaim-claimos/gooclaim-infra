<!-- rules-version: 1.0 -->
## L0 — Channel Gateway Rules

- Zero business logic in L0 — normalize and secure only; never decide what to reply or what a message means
- Signature verification mandatory on every webhook before any processing
- Always return 200 OK to Meta within 5s; all processing is async downstream
- Phone normalization: E.164 format first, then SHA-256 hash; never hash before normalizing
- Raw phone discarded immediately after hashing — never stored, logged, or persisted anywhere post-hash
- Allowlist gate mandatory: unknown phone = blocked; no exceptions
- Graceful drop for unsupported message types (sticker, reaction, video); never crash or error
- Each TPA has dedicated WABA number; `phone_number_id` in webhook identifies the tenant
- Language detection loads from `config/languages.yml`; default is HI_EN (not EN) if ambiguous or null
- Operational mode checked first (before any outbound send): SUSPENDED = zero messages out
- Template-only outbound in Phase 1; no free-text generation ever
- Session window tracked via Redis TTL (24hr WhatsApp window); auto-expires
- Dedup at L0 via Redis SET NX on `wa_message_id`; duplicate = silent 200 drop, no processing
- BullMQ publish with DLQ — 3 retries, 7-day retention on DLQ; never drop events silently
- Rate limiting: per-IP + per-tenant via Redis sliding window — enforce before processing
- Proactive reply messages carry `in_reply_to_wamid` field — preserve this in InteractionEvent
