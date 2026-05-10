# ADR-DB-06: Migration Pattern (Expand-Contract)

**Date:** 2026-05-11
**Status:** Accepted
**Deciders:** Team
**Related:** ADR-DB-02 (per-service DB), `project_database_design_rules.md` (R7)

---

## Context

13 service DBs need schema changes throughout v1.0+ lifecycle. Naive migrations cause:
- **Downtime** (DROP COLUMN while old code still reads it → crash)
- **Rolling deploy failures** (new code expects new schema, old replicas crash)
- **Rollback risk** (forward migration applied; rollback path untested)

Need a migration pattern that supports zero-downtime + safe rollback + 2-version compatibility.

---

## Decision

**All schema changes follow the Expand-Contract pattern, with mandatory reversible `downgrade()` in every Alembic migration.**

### Pattern (4 steps)

```
EXPAND
  ↓
BACKFILL
  ↓
SWITCH READS (dual-write transition)
  ↓
CONTRACT
```

---

### Step 1: EXPAND (additive only)

- Add new column / table / index — **NO removal yet**
- Old code unaffected — still reads/writes old schema
- New schema deploys without app changes

```sql
-- Example: rename column phone → phone_hash
ALTER TABLE users ADD COLUMN phone_hash VARCHAR(64) NULL;
```

### Step 2: BACKFILL (populate new schema from old)

- Async job populates new column from existing data
- Run in batches (avoid table lock)
- Validate row counts match

```python
# Async backfill
def backfill_phone_hash(batch_size=1000):
    while True:
        rows = session.query(User).filter(User.phone_hash.is_(None)).limit(batch_size).all()
        if not rows:
            break
        for user in rows:
            user.phone_hash = hash_identifier(user.phone, IdentifierType.PHONE, tenant_salt)
        session.commit()
```

### Step 3: SWITCH READS (dual-write transition)

- Deploy code that reads from NEW column primarily
- Continues to write OLD column (dual-write) for compatibility
- Monitor for 1-2 versions (FP-02 — 2-version compatibility window)

```python
# After deploy: read from new, dual-write
def get_user_by_phone(phone: str):
    phone_hash = hash_identifier(phone, IdentifierType.PHONE, tenant_salt)
    return session.query(User).filter(User.phone_hash == phone_hash).first()

def create_user(phone: str, ...):
    user = User(
        phone=phone,                                 # OLD — dual-write
        phone_hash=hash_identifier(phone, ...),       # NEW
        ...
    )
```

### Step 4: CONTRACT (drop old after grace period)

- Stop writing to old column
- Wait 1-2 versions for any straggler reads
- DROP old column

```sql
-- After 2 minor versions of dual-write
ALTER TABLE users DROP COLUMN phone;
```

---

## Reasons

- **Zero downtime** — all 4 steps deployable independently with 0 service interruption
- **Rolling deploy compatible** — both old + new replicas handle data correctly (FP-01/02)
- **Safe rollback** — if Step 4 fails, Step 3 still runs (old column may have stale data, but service works)
- **Auditable** — each migration PR shows clear forward + downgrade
- **Standard pattern** — well-known, low cognitive overhead

---

## Mandatory Rules

- **Every Alembic migration MUST have working `downgrade()` function**
- **Migrations tested in CI** — apply forward + downgrade + re-apply
- **No `DROP COLUMN`/`DROP TABLE` in single migration** — must be separate "contract" migration after grace period
- **No `ALTER COLUMN TYPE` in place** — must add new column + dual-write + switch + drop
- **No `NOT NULL` without default** on existing tables (FP-05 — would break old code inserting NULL)
- **`CREATE INDEX CONCURRENTLY`** for indexes on large tables (avoid table lock)

---

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| Big-bang migrations (single ALTER per change) | Causes downtime; rolling deploy incompatibility |
| No `downgrade()` ("we'll roll forward") | Untested rollback = no rollback; high incident risk |
| Branching schemas (one per environment) | Complexity nightmare; merge conflicts |
| Schema-management-as-code (e.g., Atlas, Liquibase) | Add 3rd party tool; Alembic sufficient for v1.0 |

---

## Consequences

### Positive
- Zero-downtime schema evolution
- Safe rollback path tested every migration
- Predictable migration cadence
- Auditor sees discipline (every migration is reversible)

### Negative
- Schema changes take 2-4 deploy cycles instead of 1 (deliberate trade-off)
- Engineers must think through dual-write logic
- Requires migration test harness in CI

### Mitigations
- Migration playbook in `gooclaim-infra/docs/runbooks/migrations.md` (TD-14)
- CI tests every migration: forward + downgrade
- Feature flag option for schema-dependent features (FP-16)

---

## Verification

Per service `docs/05-database.md`:

- [ ] Migration playbook documented
- [ ] Forward + downgrade tested locally
- [ ] CI test passes for all migrations in repo
- [ ] No NULL-without-default on existing tables

CI test pattern:

```python
def test_migrations_reversible():
    """All migrations must apply forward + downgrade cleanly."""
    alembic_upgrade("head")
    alembic_downgrade("-1")
    alembic_upgrade("head")
    # Idempotent: re-apply doesn't break
```

---

## Sample Migration Diff (good example)

```python
# alembic/versions/0042_add_phone_hash.py
"""Add phone_hash column to users.

Revision ID: 0042_phone_hash
Revises: 0041_initial
"""

def upgrade():
    op.add_column(
        "users",
        sa.Column("phone_hash", sa.String(64), nullable=True),
    )
    op.create_index("idx_users_phone_hash", "users", ["phone_hash"])

def downgrade():
    op.drop_index("idx_users_phone_hash", "users")
    op.drop_column("users", "phone_hash")
```

Note: nullable=True (FP-05). Backfill happens in separate async job, not in migration.

---

## References

- `gooclaim-infra/docs/runbooks/migrations.md` — playbook
- `Gooclaim-Sheets/Gooclaim-DB-Design.md` — Migration Playbook section
- `project_database_design_rules.md` — Hard rule R7
- 32 future-proof principles — FP-01 / FP-02 / FP-03 / FP-04 / FP-05 / FP-10 / FP-13 / FP-14
