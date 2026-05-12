# ADR-DB-04: PHI Hashing Approach (Hash-Only + Envelope Encryption Hybrid)

**Date:** 2026-05-11
**Status:** Accepted
**Deciders:** Team
**Related:** ADR-DB-03 (tenant isolation), DPDP §6/§8/§12, IRDAI

---

## Context

DPDP forbids storing PHI (phone, name, claim_id) in plaintext. Two storage strategies:

1. **Hash-only:** SHA-256 with tenant salt — irreversible, searchable, supports lookups
2. **Envelope encryption:** AES-256 + KMS-managed data key — reversible, retrievable for legitimate use

Different PHI columns need different strategies:
- **Identifiers** (phone, email, claim_id) → hash-only (lookup-only, no need to recover plaintext)
- **Names, addresses** → encryption (support workflow may need to display)
- **Secrets** (MFA seed, connector credentials) → envelope encryption (must decrypt at runtime)

---

## Decision

**Hybrid PHI strategy:**

| PHI category | Storage | Why |
|-------------|---------|-----|
| **Searchable identifiers** | SHA-256 + tenant salt → `<col>_hash` | Lookup, idempotency, dedup; no plaintext recovery needed |
| **Display-needed data** (e.g., names) | AES-256 envelope encryption → `<col>_encrypted` | Decrypt at runtime for support display |
| **Secrets** (MFA seed, connector creds) | Envelope encryption (KMS-managed key) | Decrypt at runtime for auth flow |
| **Non-PHI metadata** (timestamps, status) | Plaintext | Not regulated |

### Single source of truth

`gooclaim_shared.phi.hasher` module — only place hashing happens.

```python
from gooclaim_shared.phi import hash_identifier, IdentifierType

# Phone (E.164 normalized)
phone_hash = hash_identifier(phone, IdentifierType.PHONE, tenant_salt)

# Email (lowercased)
email_hash = hash_identifier(email, IdentifierType.EMAIL, tenant_salt)

# Generic ID
claim_id_hash = hash_identifier(claim_id, IdentifierType.GENERIC, tenant_salt)
```

### Tenant salt

Each tenant gets unique salt (stored in `gooclaim-auth`'s `connector_credentials` encrypted store). Prevents cross-tenant rainbow-table attacks.

### Envelope encryption

For retrievable data:

```
Plaintext → AES-256 → encrypted_blob
                           ↑
              Data Encryption Key (DEK)
                           ↑
              Key Encryption Key (KEK) ← AWS KMS
```

DEK rotated per row write; KEK rotated quarterly.

---

## Reasons

- **DPDP §6/§8 compliance** — no plaintext PHI persistence
- **Hash-only for identifiers preserves lookups** — `WHERE phone_hash = :h` still works
- **Envelope encryption only where retrieval needed** — minimizes attack surface (encrypted blob can't be brute-forced from a leak the way a hash can)
- **Tenant salt prevents cross-tenant attacks** — even if hash leaked, can't map to another tenant's user
- **Single hashing module** = single audit point — auditor reviews one file (`hasher.py`) to verify approach
- **KMS-backed KEK** ensures keys aren't co-located with data

---

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| Plaintext PHI with column-level encryption only | Encryption keys often in same DB or app config; weaker than envelope |
| Hash-only for everything | Names/addresses needed for display; pure hash = lost data |
| Per-column custom hashing | Drift across services; auditor nightmare |
| PostgreSQL pgcrypto | Tied to single Postgres instance; hard to rotate keys; no separation of duties |

---

## Consequences

### Positive
- DPDP §6/§8 compliance
- Searchable without plaintext exposure
- KMS separation of duties
- Single module enforces consistency

### Negative
- Hash-only PHI cannot be recovered (intentional, but support flows must use ID-based, not phone-based, lookup)
- Envelope encryption requires KMS calls at runtime (latency cost)
- Tenant salt rotation is non-trivial (one-time event per tenant, not regular)

### Mitigations
- KMS calls cached per request (1-2ms overhead negligible)
- Support flows redesigned to use opaque user_id (UUID), not phone
- Tenant salt rotation = ADR-future event with explicit migration plan

---

## DPDP §12 Right-to-be-Forgotten

Hash-only PHI is **already pseudonymized** — RTBF compliance simpler:

1. Soft-delete user record (set `deleted_at`)
2. Hash entries become orphans (no plaintext to "delete")
3. Audit ledger entries reference hash only — preserves IRDAI immutability
4. Hard-delete pipeline (30 days post soft-delete) drops user record

For envelope-encrypted data:
1. Destroy DEK for that user → ciphertext becomes irrecoverable
2. KMS audit log records deletion timestamp

---

## Implementation Verification

Per service `docs/05-database.md`:

- [ ] PHI Classification Table lists every PII column with strategy
- [ ] Plaintext PHI columns absent (grep audit clean)
- [ ] All hashing routes through `gooclaim_shared.phi.hasher`
- [ ] Tenant salt provisioning documented
- [ ] KMS rotation cadence documented (quarterly)

---

## References

- `gooclaim-shared/src/gooclaim_shared/phi/hasher.py` — hashing module
- `gooclaim-shared/src/gooclaim_shared/enums/identifier_type.py` — supported identifier types
- ADR-DB-03 — Tenant isolation (relates to tenant salt)
- DPDP Act §6/§8/§12 — compliance requirements
- AWS Secrets Manager — KMS key management
