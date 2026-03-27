## L2 — Truth Layer Rules

- No source, no answer: readiness STALE or NOT_CONNECTED = fail closed; never serve stale data
- Tenant isolation absolute: every connector call scoped by tenant_id; cross-tenant lookup is architecturally impossible
- Fallback order is fixed and immutable: API → CSV/SFTP Feed → RPA → Fail Closed; never reversed or skipped
- Phase 1 + 2 read-only: no write-back to external systems; Phase 3 only with human approval + operational mode
- All credentials in AWS Secrets Manager — no API keys, passwords, or tokens in code/config/env
- Error taxonomy: exactly 6 standard codes — NOT_FOUND, MULTIPLE_MATCH, AUTH_REQUIRED, SOURCE_DOWN, TIMEOUT, STALE; no custom codes
- NOT_FOUND or STALE → do NOT retry; user error or known state
- SOURCE_DOWN or TIMEOUT → retry 3x with backoff
- AUTH_REQUIRED → tier up identity, no retry
- Circuit breaker: CLOSED/OPEN/HALF_OPEN — must be Redis-backed per tenant
- IHMSConnector is supplementary only — never overrides ICMSConnector data
- Human ticket creation is code-based, never LLM; guaranteed via CaseService.create_human_ticket()
- Timeout budget: 2s P95 for real-time requests (RW1/RW3); 1.5s for voice blocking path
- member_id_hash is PHI — never log or return as plaintext
