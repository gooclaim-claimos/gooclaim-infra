# ADR-DB-01: BCNF Target for All Service DBs (Not 5NF)

**Date:** 2026-05-11
**Status:** Accepted
**Deciders:** Team
**Supersedes:** —
**Related:** ADR-DB-02 (per-service DB), `project_database_design_rules.md` (12 hard rules)

---

## Context

Gooclaim has 13 service databases each with own schema. Need to lock normalization target to prevent drift across teams + ensure schema reviews are objective.

Two practical options:
- **BCNF** (Boyce-Codd Normal Form): every non-trivial functional dependency has a superkey on the LHS
- **5NF** (Fifth Normal Form): no non-trivial join dependencies

5NF is theoretically purer; BCNF is the industry-practical sweet spot.

---

## Decision

**Use BCNF as the target for all 13 service DB schemas. Do NOT pursue 5NF.**

JSONB columns are allowed for genuinely flexible data (per FP-08) — these don't violate BCNF since the JSONB blob is treated as a single attribute.

---

## Reasons

- **5NF is over-engineering for v1.0** — eliminates join dependencies that almost never occur in single-tenant scoped CRUD workflows
- **BCNF prevents the most common bugs** — partial dependencies, transitive dependencies, update anomalies
- **Tooling support** — SQLAlchemy 2.0 + Pydantic + alembic match BCNF naturally; 5NF requires manual decomposition tracking
- **Reviewability** — engineers can verify BCNF by inspection in PR reviews; 5NF requires formal proof
- **Per-tenant scoping** is the dominant query pattern → BCNF schemas with `(tenant_id, ...)` composite keys are sufficient
- **Future denormalization** is easier from BCNF than from 5NF (FP-18 — denormalize only when measurable read pain)

---

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| 5NF | Over-engineered; little practical benefit at pilot scale; harder to review/maintain |
| 3NF | Insufficient — allows BCNF anomalies (partial keys + transitive on candidate key) |
| Denormalized (no normal form target) | Increases write amplification, harder to maintain consistency, audit-unfriendly |
| Per-team choice | Causes schema drift across 13 services; review nightmare |

---

## Consequences

### Positive
- Schema reviews objective ("is this BCNF?" — yes/no)
- Predictable migration patterns
- Backward compatibility easier (fewer table interdependencies)
- Compliance auditor sees consistent schema discipline across services

### Negative
- Some queries may need joins where 5NF would have inlined data (acceptable)
- Engineers must understand BCNF (training material in `gooclaim-infra/docs/`)

### Mitigations
- Read replicas for analytics-heavy workloads (FP-29)
- Materialized views for frequently-joined data
- Per-service `docs/05-database.md` documents indexes that compensate for joins

---

## Implementation

- Every per-service DB design doc must include "BCNF compliance verified" check
- Schema review PR template includes "BCNF check passed" item
- Migration test (CI) validates no schema deviations beyond approved JSONB usage

## Verification

For each service DB at Stage 1 sign-off:
- [ ] All tables in BCNF (no transitive dependencies)
- [ ] JSONB columns documented + Pydantic-validated
- [ ] No denormalization without ADR override

---

## References

- `project_database_design_rules.md` — 12 hard rules (R8 references this ADR)
- `Gooclaim-Sheets/Gooclaim-DB-Design.md` — Part C framework
- `gooclaim-shared/docs/05-database.md` — BCNF examples in mixin patterns
