# ADR-DB-02: Per-Service Database (No Shared Schema)

**Date:** 2026-05-11
**Status:** Accepted
**Deciders:** Team
**Related:** ADR-DB-01 (BCNF), ADR-DB-08 (saga pattern), `project_database_design_rules.md` (R1)

---

## Context

13 microservices need persistence. Two architectural choices:
- **Per-service DB:** each service owns its own logical database with its own user
- **Shared monolithic DB:** all services share one database with table prefixes

Microservice principles say per-service DB. But cross-service queries (joins, FKs) require either eventual consistency OR shared DB.

---

## Decision

**Each of 13 services owns its own logical PostgreSQL database. No shared schemas. No cross-service foreign keys.**

| Service | Owns DB |
|---------|---------|
| gooclaim-auth | `auth_db` |
| gooclaim-audit | `audit_db` |
| gooclaim-gateway | `gateway_db` |
| gooclaim-engine | `engine_db` |
| gooclaim-truth | `truth_db` |
| gooclaim-knowledge | `knowledge_db` |
| gooclaim-outbound | `outbound_db` |
| gooclaim-policy | `policy_db` |
| gooclaim-template-registry | `template_registry_db` |
| gooclaim-tenant-config | `tenant_config_db` |
| gooclaim-model-gateway | `model_gateway_db` |
| gooclaim-connector-hub | `connector_hub_db` |
| gooclaim-whatsapp | `whatsapp_db` |

All 13 logical DBs live in same Azure PostgreSQL Flexible Server (single instance, multiple logical DBs).

Cross-service consistency uses **saga pattern** (ADR-DB-08) — events emitted via audit ledger.

---

## Reasons

- **Tenant isolation cleaner per-DB** — single DB per service simplifies DPDP §6 compliance audit
- **Independent migrations** — service teams deploy schema changes independently without coordination
- **Failure isolation** — schema bug in one service can't corrupt another's data
- **Per-service DB user (least privilege)** — `gooclaim_auth_user` only accesses `auth_db` (FP-28)
- **Saga pattern enables eventual consistency** without DB-level FKs (ADR-DB-08)
- **Schema drift contained** — each service evolves at its own pace
- **Compliance auditor sees clear ownership** — "who owns this column?" is unambiguous

---

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| Shared monolithic DB | Tight coupling; teams block each other on migrations; tenant isolation harder |
| Shared DB + table prefixes (e.g., `auth.users`, `engine.runs`) | Same coupling problem; service can't enforce its own schema rules |
| Multi-master (one DB per service in separate clusters) | Over-engineered for v1.0 pilot scale (13 logical DBs in 1 cluster is sufficient) |
| Per-service NoSQL (MongoDB, etc.) | Loses ACID, harder for IRDAI audit ledger immutability |

---

## Consequences

### Positive
- Microservice autonomy
- Clear data ownership
- Per-service DB user → minimum privilege
- Independent migration timing
- Compliance auditor-friendly

### Negative
- Cross-service queries require app-level joins or saga events (no SQL JOIN across DBs)
- Slightly higher operational overhead (13 logical DBs to monitor vs 1)
- Connection pool config is per-service

### Mitigations
- All 13 DBs in 1 Postgres cluster (low op overhead vs separate instances)
- Saga pattern (ADR-DB-08) handles cross-service consistency
- Read replicas (FP-29) for analytics workloads

---

## Cluster Architecture

```
Azure Database for PostgreSQL — Flexible Server (centralindia)
   │
   ├── auth_db                  (owned by gooclaim-auth)
   ├── audit_db                 (owned by gooclaim-audit, INSERT-only)
   ├── gateway_db               (owned by gooclaim-gateway)
   ├── engine_db                (owned by gooclaim-engine)
   ├── truth_db                 (owned by gooclaim-truth)
   ├── knowledge_db             (owned by gooclaim-knowledge, + pgvector)
   ├── outbound_db              (owned by gooclaim-outbound)
   ├── policy_db                (owned by gooclaim-policy)
   ├── template_registry_db     (owned by gooclaim-template-registry)
   ├── tenant_config_db         (owned by gooclaim-tenant-config)
   ├── model_gateway_db         (owned by gooclaim-model-gateway)
   ├── connector_hub_db         (owned by gooclaim-connector-hub)
   ├── whatsapp_db              (owned by gooclaim-whatsapp)
   ├── temporal                 (Temporal-managed schema)
   ├── temporal_visibility      (Temporal-managed schema)
   └── grafana                  (Grafana-managed schema)
```

16 logical DBs in 1 cluster.

---

## References

- `Gooclaim-Sheets/Gooclaim-DB-Design.md` — Part A (13 service DBs) + Part B (3 infra DBs)
- ADR-DB-08 — Saga pattern (no cross-service FKs)
- `project_database_design_rules.md` — Hard rule R1
- `project_cloud_aws_or_azure.md` — Azure compute lock
