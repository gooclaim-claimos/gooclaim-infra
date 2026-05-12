# ADR-DB-07: Partitioning Strategy (Monthly RANGE on event_time for audit_events)

**Date:** 2026-05-11
**Status:** Accepted
**Deciders:** Team
**Related:** ADR-DB-05 (audit immutability), IRDAI 7-year retention, `project_database_design_rules.md` (R5)

---

## Context

`audit_events` is the largest table by row count — every automated decision across all 13 services emits an event. Estimated growth:

| Scale | Events/day | Events/year | Table size (est.) |
|-------|------------|-------------|-------------------|
| Pilot (5 TPAs × 100 claims/day) | ~5,000 | ~1.8M | ~1 GB |
| Year 2 (50 TPAs) | ~50,000 | ~18M | ~10 GB |
| Year 3 (200 TPAs) | ~200,000 | ~73M | ~40 GB |
| Year 7 (IRDAI retention) | ~1.4M | ~500M+ | ~250 GB+ |

7-year retention with no partitioning = unmanageable single table. Indexes degrade, query latency rises, retention drops require painful DELETE.

---

## Decision

**Partition `audit_events` by `event_time` using monthly RANGE partitions. Auto-create future partitions. Drop expired partitions for retention enforcement.**

### Pattern

```sql
CREATE TABLE audit_events (
    event_id BIGSERIAL,
    tenant_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(128) NOT NULL,
    -- ...
    event_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (event_id, event_time)
) PARTITION BY RANGE (event_time);

-- Create monthly partitions
CREATE TABLE audit_events_2026_01 PARTITION OF audit_events
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE audit_events_2026_02 PARTITION OF audit_events
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
-- ... 84 partitions for 7 years
```

### Auto-creation (scheduled job)

A Temporal cron job runs monthly to:
1. Create next month's partition (1 month ahead)
2. Drop partition older than 84 months (7 years)
3. Audit-log both events (`PARTITION_CREATED`, `PARTITION_DROPPED`)

```python
# Pseudo-code for cron
def maintain_partitions():
    next_month = current_month + 1
    create_partition(next_month)  # CREATE TABLE audit_events_YYYY_MM ...
    
    expire_month = current_month - 84
    if partition_exists(expire_month):
        drop_partition(expire_month)  # DROP TABLE audit_events_YYYY_MM
        emit_audit_event("PARTITION_DROPPED", target=expire_month)
```

---

## Reasons

- **Query performance** — partition pruning means queries with `WHERE event_time >= '2026-05'` only scan relevant partitions, not full 250GB table
- **Retention enforcement** — dropping a partition is O(seconds), vs DELETE on 1M rows = O(minutes) + dead tuple bloat
- **Index efficiency** — each partition has its own indexes; smaller indexes = faster lookups
- **Backup granularity** — can backup/restore individual months
- **IRDAI 7yr retention** — partition expiry maps directly to retention requirement
- **Vacuum efficiency** — VACUUM on small partition < 1s; on 250GB single table = hours

---

## Why Monthly (Not Daily / Yearly)

| Granularity | Pro | Con | Verdict |
|-------------|-----|-----|---------|
| Daily | Finest backup granularity | 7 × 365 = 2,555 partitions; metadata overhead | Too fine |
| Weekly | Granular | 7 × 52 = 364 partitions; awkward boundaries | Acceptable |
| **Monthly** | **84 partitions / 7 yr; aligns with retention windows** | Backups slightly larger | ✅ Chosen |
| Quarterly | Fewer partitions | Coarse retention; large per-partition | Too coarse |
| Yearly | Minimum partitions | One partition = full year of data; slow queries | Too coarse |

Monthly is the sweet spot — 84 partitions over 7 years, aligns with retention windows, manageable metadata overhead.

---

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| No partitioning | Unmanageable at year 3+ (40 GB+ single table) |
| LIST partitioning by tenant_id | Adding new tenants = new partitions = operational overhead |
| HASH partitioning | Doesn't help with retention drops; loses time-locality |
| External time-series DB (TimescaleDB) | Adds new tech; partitioned vanilla Postgres sufficient |
| Postgres declarative partitioning by event_type | event_type is high-cardinality; thousands of partitions |

---

## Consequences

### Positive
- Query latency stable as data grows
- Retention enforcement is partition DROP (fast)
- Backup/restore granularity (monthly)
- Auditor sees clear retention pattern

### Negative
- Slightly more complex schema (PARTITION BY clause)
- Cross-month queries scan multiple partitions (acceptable)
- Foreign keys CANNOT cross partitions (no FK on `audit_events.event_id` from another table)
- Requires monthly cron job for partition maintenance

### Mitigations
- **Audit immutability still enforced** (ADR-DB-05) — REVOKE UPDATE, DELETE applies to all partitions
- **Cron job monitored** — alert if monthly partition creation skipped
- **Migration playbook** documents partition creation + drop procedures

---

## Other Tables — Not Partitioned

For v1.0, **only `audit_events` is partitioned**. Other tables:

| Service | Largest tables | Partition? | Why |
|---------|----------------|-----------|-----|
| auth | users, sessions | No | <100K rows expected |
| engine | workflow_runs | No | TTL via cleanup, <1M rows |
| knowledge | kb_chunks | No | Content-based; pgvector index handles size |
| outbound | outbound_intents | Maybe v1.1 | If >10M rows by year 1, consider monthly |

Partitioning has overhead — apply only when data growth justifies.

---

## v1.1+ Candidates for Partitioning

If pilot data shows growth pressure:
- `outbound_intents` — by `created_at` (monthly)
- `gateway_db.interaction_events` — by `created_at` (monthly)
- `model_gateway_db.usage_log` — by `ts` (monthly)
- `engine_db.workflow_steps` — by `created_at` (quarterly)

Each requires its own ADR.

---

## Verification

Per service docs/05-database.md:

- [ ] `audit_events` PARTITION BY RANGE (event_time) confirmed
- [ ] Monthly partitions exist for current + next month
- [ ] Partition pruning verified via `EXPLAIN ANALYZE`
- [ ] Cron job for partition maintenance scheduled in Temporal
- [ ] Drop-partition runbook documented

---

## References

- `gooclaim-audit/docs/05-database.md` — full audit_events schema with partitioning
- ADR-DB-05 — audit immutability
- `project_database_design_rules.md` — Hard rule R5 (partitioning)
- IRDAI 7-year retention requirement (compliance binder)
