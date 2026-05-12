# ADR-DB-05: Audit Ledger Immutability via DB-Level REVOKE

**Date:** 2026-05-11
**Status:** Accepted
**Deciders:** Team
**Related:** ADR-DB-07 (partitioning), IRDAI 7-year retention, `project_database_design_rules.md` (R5)

---

## Context

IRDAI mandates audit ledger immutability + 7-year retention. Application bugs, malicious tampering, or admin errors must not be able to modify or delete audit records.

Three enforcement layers:
1. **Application-level** — code conventions ("don't write UPDATE on audit_events")
2. **Schema-level** — database constraints (e.g., `BEFORE UPDATE` trigger raising error)
3. **Permission-level** — `REVOKE UPDATE, DELETE` from the role used by services

Application alone is insufficient — bugs slip through code review. Schema triggers can be disabled by DBAs. Permission-level is the strongest defense.

---

## Decision

**Enforce audit ledger immutability at the Postgres role level. The application's DB user has INSERT-only access to `audit_events`. UPDATE and DELETE are REVOKED at provision time.**

```sql
-- Setup (one-time at provisioning)
GRANT INSERT, SELECT ON audit_events TO gooclaim_audit_writer;
REVOKE UPDATE, DELETE ON audit_events FROM gooclaim_audit_writer;

-- Read-only role for analytics
GRANT SELECT ON audit_events TO gooclaim_audit_reader;
REVOKE INSERT, UPDATE, DELETE ON audit_events FROM gooclaim_audit_reader;

-- Schema-owner (admin) role kept separate; only used for migrations + partition creation
GRANT ALL ON audit_events TO gooclaim_audit_admin;
```

Service runs as `gooclaim_audit_writer` — even if app code attempts UPDATE/DELETE, Postgres rejects.

---

## Reasons

- **Auditor-defensible** — `\dp audit_events` in psql shows REVOKE; instant proof of immutability
- **Defense-in-depth** — application bugs caught at DB layer
- **Separation of duties** — admin role (for partition creation) is separate from writer role
- **IRDAI 7-year retention** — partitions dropped at expiry, never UPDATE-d
- **Tamper-evident chain** — paired with SHA-256 chained signatures (each event signs prev event), any tampering visible in the chain

---

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| Application-level "don't UPDATE" convention | Bug-prone; not auditor-defensible |
| BEFORE UPDATE trigger raising error | DBA can disable trigger; less defensible |
| Append-only filesystem (e.g., ZFS snapshots) | Adds complexity; same effect achieved via REVOKE |
| Blockchain-based audit | Massive overkill; latency unacceptable for 1000+ events/sec |
| WORM storage (Write-Once-Read-Many) | Postgres doesn't natively support; would require external append-only store |

---

## Consequences

### Positive
- IRDAI-defensible immutability (proof: `\dp audit_events`)
- Application bug containment
- Clear role-based audit trail
- Separation of duties

### Negative
- Can't fix legitimate audit errors via UPDATE (e.g., timestamp typo) — must be addressed by appending correction event
- Partition dropping (after 7 years) requires admin role, not service role
- Cannot soft-delete audit events (intentional — soft-delete violates immutability)

### Mitigations
- **Correction events** — if audit record needs correction, INSERT a new event with `event_type='AUDIT_CORRECTION'` referencing original
- **Migration playbook** — partition drops use admin role, scheduled via Temporal cron (verifiable)
- **Tamper-evident chain** — even if admin is compromised, chained signatures detect modifications

---

## Implementation

### Postgres setup (one-time at provisioning)

```sql
-- Connect as superuser
CREATE DATABASE audit_db OWNER gooclaim_audit_admin;
\c audit_db

CREATE TABLE audit_events (
    event_id BIGSERIAL,
    tenant_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(128) NOT NULL,
    actor VARCHAR(256),
    target VARCHAR(256),
    payload_json JSONB,
    signature CHAR(64) NOT NULL,
    event_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- ...
    PRIMARY KEY (event_id, event_time)
) PARTITION BY RANGE (event_time);

-- Indexes
CREATE INDEX idx_audit_events_tenant_time ON audit_events (tenant_id, event_time);
CREATE INDEX idx_audit_events_type_time ON audit_events (event_type, event_time);

-- Roles
CREATE ROLE gooclaim_audit_admin;        -- For schema/partition admin only
CREATE ROLE gooclaim_audit_writer;       -- For service to INSERT
CREATE ROLE gooclaim_audit_reader;       -- For analytics SELECT only

GRANT INSERT, SELECT ON audit_events TO gooclaim_audit_writer;
REVOKE UPDATE, DELETE ON audit_events FROM gooclaim_audit_writer;

GRANT SELECT ON audit_events TO gooclaim_audit_reader;
REVOKE INSERT, UPDATE, DELETE ON audit_events FROM gooclaim_audit_reader;

GRANT ALL ON audit_events TO gooclaim_audit_admin;
```

### Verification (in CI + audit binder)

```sql
-- This must show INSERT-only for writer role
\dp audit_events
-- Output should show: 
--   gooclaim_audit_writer = arwd → "ar" (only)
--   gooclaim_audit_reader = arwd → "r"  (only)
```

```python
def test_writer_cannot_update():
    """IRDAI immutability enforcement test."""
    with engine.connect() as conn:  # Connection as audit_writer
        conn.execute(text("INSERT INTO audit_events (...) VALUES (...)"))
        with pytest.raises(InsufficientPrivilege):
            conn.execute(text("UPDATE audit_events SET event_type = 'tampered'"))
```

---

## SHA-256 Chained Signature (Defense-in-depth)

Each `audit_events` row's `signature` column = SHA-256 of:
- Event payload
- Previous event's signature (chain link)
- Tenant salt

If any past event tampered, chain breaks at next event — visible to auditor.

---

## References

- `gooclaim-audit/docs/05-database.md` — audit_events schema details
- `gooclaim-audit/src/.../models/audit_event.py` — model + signing logic
- IRDAI compliance binder — `compliance.gooclaim.com/evidence/irdai-immutability/`
- ADR-DB-07 — Partitioning (drops not UPDATEs)
