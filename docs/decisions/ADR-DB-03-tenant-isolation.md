# ADR-DB-03: Tenant Isolation Strategy (Row-Level Default + Escalation Path)

**Date:** 2026-05-11
**Status:** Accepted
**Deciders:** Team
**Related:** ADR-DB-02 (per-service DB), DPDP §6, `project_database_design_rules.md` (R2)

---

## Context

DPDP §6 mandates tenant data isolation. Three implementation levels (most-permissive to most-restrictive):

1. **Row-level (RLS):** `tenant_id` column on every table; queries filtered by `WHERE tenant_id = ?`
2. **Schema-level:** Each tenant gets its own Postgres schema (namespace) within shared DB
3. **DB-level:** Each tenant gets its own physical database

Trade-off: stricter isolation = higher cost + more operational overhead.

Pilot: 5-10 friendly TPAs. Future: 50-200 TPAs.

---

## Decision

**Default isolation = Row-Level via mandatory `tenant_id` column on every tenant-scoped table.** Provide explicit escalation path to schema-level or DB-level for high-risk tenants.

### Default (row-level)

- Every tenant table has `tenant_id: str` column (`gooclaim_shared.db.TenantMixin`)
- Index on `tenant_id` for query performance
- Application-layer middleware (`gooclaim_shared.middleware.tenant_context`) enforces tenant scoping
- Postgres Row-Level Security (RLS) policies as defense-in-depth (where supported)
- `tenant_id = "global"` reserved for cross-tenant data (e.g., scout-published Global KB chunks)

### Escalation path (per-tenant)

| Trigger | Isolation level |
|---------|-----------------|
| Standard pilot TPA (5-10) | Row-level (default) |
| Enterprise tenant with explicit DPA clause | Schema-level (separate Postgres schema) |
| Government-tier tenant or PII-mass-data | DB-level (separate logical DB) |
| Multi-region / DR | DB-level + cross-region replication (v3.0) |

Escalation path documented per service in `docs/05-database.md` "Tenancy Model" section.

---

## Reasons

- **Pilot scale (5-10 tenants) doesn't justify schema-level overhead** — row-level sufficient
- **Row-level enables shared connection pool** — significant cost saving with PgBouncer (FP-30)
- **Query patterns are tenant-scoped anyway** — single `WHERE tenant_id` is the dominant filter
- **DPDP §6 compliance possible at row-level** with proper enforcement (middleware + RLS policies)
- **Escalation path future-proofs** for enterprise customers with stricter requirements (FP-27)
- **Auditor-defensible** — single `tenant_id` column + middleware test = clear isolation proof

---

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| Schema-level by default for all tenants | Connection pool fragmentation, 10× operational overhead at pilot scale |
| DB-level by default for all tenants | Postgres has soft 50-DB limit per cluster; not scalable to 200 TPAs |
| Per-tenant Postgres cluster | 10-100× cost; only viable for V3 enterprise tier |
| App-only isolation (no DB-level enforcement) | Defense-in-depth principle violated; one application bug → cross-tenant leak |

---

## Consequences

### Positive
- Cost-effective at pilot scale
- Predictable query patterns
- DPDP §6 compliance achievable with middleware + RLS
- Clear escalation path for enterprise tenants

### Negative
- Application bug in middleware = potential cross-tenant leak (HIGH risk)
- All tables must have `tenant_id` column (no exceptions for tenant data)
- Cross-tenant queries (e.g., platform-wide analytics) require explicit `IS NULL` checks or `"global"` filter

### Mitigations
- **Middleware always applied** at API layer — `require_tenant()` dependency injection
- **Postgres RLS policies** as backup — even if middleware fails, RLS blocks cross-tenant read
- **Compliance test** in every service: cross-tenant SELECT returns 0 rows
- **PR review checklist** — every new query reviewed for tenant scoping

---

## Implementation Pattern

### TenantMixin (in `gooclaim-shared`)

```python
from gooclaim_shared.db import Base, TenantMixin

class WorkflowRun(Base, TenantMixin, ...):
    # tenant_id: str — automatically added with index
    ...
```

### Query enforcement

```python
# CORRECT — middleware-injected tenant
@app.get("/runs")
async def list_runs(tenant_id: str = Depends(require_tenant)):
    return db.query(WorkflowRun).filter(WorkflowRun.tenant_id == tenant_id).all()

# WRONG — caller-supplied tenant (bypassable)
async def list_runs_unsafe(tenant_id: str):  # DO NOT DO THIS
    return db.query(WorkflowRun).filter(WorkflowRun.tenant_id == tenant_id).all()
```

### Postgres RLS (defense-in-depth)

```sql
-- Enable RLS on tenant tables
ALTER TABLE workflow_runs ENABLE ROW LEVEL SECURITY;

-- Policy: only see rows matching session-set tenant_id
CREATE POLICY tenant_isolation ON workflow_runs
    USING (tenant_id = current_setting('app.tenant_id', true));
```

### Verification (per service)

```python
def test_cross_tenant_select_returns_zero():
    """DPDP §6 isolation enforcement."""
    set_tenant("tenant-a")
    db.add(WorkflowRun(tenant_id="tenant-a", ...))
    db.commit()
    
    set_tenant("tenant-b")
    rows = db.query(WorkflowRun).all()
    assert len(rows) == 0
```

---

## References

- `gooclaim-shared/src/gooclaim_shared/db/mixins.py` — `TenantMixin`
- `gooclaim-shared/src/gooclaim_shared/middleware/tenant_context.py` — runtime enforcement
- `project_database_design_rules.md` — Hard rule R2
- `Gooclaim-Sheets/Gooclaim-DB-Design.md` — DPDP §6 compliance section
