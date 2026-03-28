---
rules-version: "1.0"
description: Generate test files mirroring the src/ folder structure. Creates unit tests for every module and integration tests for every connector. Usage: /test or /test src/gateway/webhook.py
---

# /test — Generate Test Cases

When this skill is invoked, generate test files that mirror the `src/` folder structure exactly.

## How to invoke

```
/test                              ← generate tests for all src/ files missing tests
/test src/gateway/webhook.py       ← generate tests for one specific file
/test unit                         ← only unit tests
/test integration                  ← only integration tests
```

---

## Step 1 — Read the source file(s)

Before writing any test, read the actual source file fully. Understand:
- Every function/method and what it does
- Input types and return types
- What can go wrong (exceptions, edge cases)
- External dependencies (DB, Redis, HTTP calls, queues)

---

## Step 2 — Mirror the folder structure

```
src/
├── gateway/
│   ├── webhook.py
│   └── lang_detect.py
└── services/
    └── claim.py

tests/
├── unit/
│   ├── gateway/
│   │   ├── test_webhook.py       ← mirrors src/gateway/webhook.py
│   │   └── test_lang_detect.py
│   └── services/
│       └── test_claim.py
└── integration/
    ├── test_cms_connector.py     ← for every connector (L2, L3, L5)
    └── test_whatsapp_adapter.py
```

**Rule:** `src/foo/bar.py` → `tests/unit/foo/test_bar.py`

---

## Step 3 — What to test per layer

### L0 — Channel Gateway
- Webhook signature verification — valid sig passes, invalid sig = 401
- Phone normalization — E.164 format, then SHA-256 hash
- Language detection — HI, EN, HI_EN, ambiguous → HI_EN default
- Dedup — same `wa_message_id` twice = second silently dropped
- Unsupported message types (sticker, reaction) = graceful drop, no crash
- Operational mode SUSPENDED = zero outbound
- Unknown phone (not in allowlist) = blocked

### L1 — Workflow Engine
- Intent classification — RW1/RW2/RW3/UNKNOWN for each language
- Entity extraction — claim_id from HI, EN, HI_EN messages
- fraud_suspect flag — 5+ NOT_FOUND in session triggers flag
- Session restore — last_claim_id + last_intent loaded correctly
- DPDP consent gate — no consent = workflow blocked
- Operational mode check — SUSPENDED = immediate return before any L2 call
- RW1 completes < 3s
- RW3 KB miss → escalate to human

### L2 — Truth Layer
- Happy path — claim found, correct data returned
- NOT_FOUND — claim does not exist
- MULTIPLE_MATCH — ambiguous claim_id
- SOURCE_DOWN — CMS API down → fallback to CSV feed
- TIMEOUT — API timeout → retry 3x then fallback
- Circuit breaker — OPEN state uses feed, HALF_OPEN tests recovery
- Tenant isolation — tenant A cannot see tenant B data
- Read-only — no write methods exist on ICMSConnector in Phase 1
- Rate limit — CMS API 10 req/min throttle respected

### L3 — Knowledge Layer
- KB lookup — similarity > 0.65 returns result
- KB miss — similarity < 0.65 = KB_MISS, escalate
- TenantFilter — every query scoped by tenant_id
- Content Safety Gate — C0 through C5 pipeline
- OCR confidence < 0.6 = chunk rejected
- Chunk dedup — same content hash = rejected

### L4 — Learning Loop
- Signal capture — correct fields written, PHI fields never read
- Passive only — no model promotion in Phase 1
- Tenant scoping — signals only read for own tenant

### L5 — Outbound Engine
- TRAI DND check — DND number = blocked
- Quiet hours — message outside 09:00-21:00 IST = queued
- SUSPENDED mode = zero sends
- Idempotency — same intent_id twice = second silently skipped
- Template rendering — correct template + language variant
- Delivery tracking — receipt logged as audit event

### L6 — Policy Gate
- T1 forbidden phrase — blocked
- T2 semantic violation — Guardrails AI blocks
- T3 PHI redaction — phone/name/claim_id stripped from output
- T4 source check — output not traceable to approved template = blocked
- RBAC — role without permission = 403
- Consent revocation — mid-session revoke = immediate block

### L7 — Observability
- Metrics emitted correctly for each event type
- PHI not in any metric label
- tenant_id + trace_id in every log line

---

## Step 4 — Test structure per file

```python
# tests/unit/gateway/test_webhook.py

import pytest
from unittest.mock import patch, MagicMock

# ─── HAPPY PATH ───────────────────────────────────────────
class TestWebhookSignatureVerification:
    def test_valid_signature_passes(self): ...
    def test_invalid_signature_returns_401(self): ...
    def test_missing_signature_returns_401(self): ...

# ─── EDGE CASES ───────────────────────────────────────────
class TestPhoneNormalization:
    def test_indian_number_normalized_to_e164(self): ...
    def test_phone_hashed_after_normalization(self): ...
    def test_raw_phone_not_stored(self): ...

# ─── ERROR PATHS ──────────────────────────────────────────
class TestGracefulDrop:
    def test_sticker_message_dropped_silently(self): ...
    def test_reaction_message_dropped_silently(self): ...
    def test_unknown_phone_blocked(self): ...
```

---

## Step 5 — Integration test rules

- Integration tests go in `tests/integration/`
- Named `test_{connector_name}.py` — e.g. `test_cms_connector.py`
- **Never mock the connector itself** — test against real interface
- Use test doubles for external APIs (respx for HTTP, fakeredis for Redis)
- Always test the full fallback chain (API → Feed → RPA → Fail Closed for L2)
- Test circuit breaker state transitions

---

## Rules

- Never mock ModelGateway in integration tests — use test doubles
- Every test is independent — no shared state between tests
- Use `freezegun` for time-dependent tests (TTL, session expiry, quiet hours)
- Use `factory-boy` for test data — never hardcode claim IDs or phone numbers
- PHI in test data must be fake — never use real phone numbers or names
- Tests must pass with `tox -e test` — run locally before declaring done
- Coverage target: 80% minimum per file
