# ADR-DB-08: Saga Pattern for Cross-Service Consistency (No Cross-Service FKs)

**Date:** 2026-05-11
**Status:** Accepted
**Deciders:** Team
**Related:** ADR-DB-02 (per-service DB), `project_database_design_rules.md` (R6)

---

## Context

13 microservices each own their own DB (ADR-DB-02). But business workflows span multiple services:

- **RW1 claim status:** gateway → engine → truth → policy → outbound
- **RW2 pending docs:** gateway → engine → temporal → connector-hub → outbound
- **TPA onboarding:** auth (create org) → tenant-config (set op_mode) → connector-hub (test connector) → audit (log success)

These workflows need cross-service consistency: "if engine started a workflow, audit must record it; if outbound failed to send, engine should know".

**Two strategies for cross-service consistency:**

1. **Distributed transactions (2PC)** — XA-style commit across multiple DBs
2. **Saga pattern** — eventually consistent via events; compensating actions on failure

---

## Decision

**Use Saga pattern. NO cross-service foreign keys. NO distributed transactions. Cross-service consistency via events emitted to `audit_events` (the platform-wide event log).**

### Saga implementation

Each service:
1. Performs its local transaction (atomic within its own DB)
2. Emits an `AuditEvent` describing what happened
3. Subscribers (other services) react to events as needed

If a step fails:
- Local transaction rolls back (single-DB atomicity)
- Service emits `*_FAILED` event
- Compensating saga step kicks off (e.g., refund, retry, escalate)

### Event flow example (RW1 claim status)

```
gateway: receives WhatsApp message
   │ Local txn: INSERT into interaction_events
   │ Emit: INTERACTION_RECEIVED
   ▼
engine: starts RW1 workflow
   │ Local txn: INSERT into workflow_runs
   │ Emit: WORKFLOW_STARTED
   ▼
truth: fetches claim from TPA CMS
   │ Local txn: INSERT into claim_cache
   │ Emit: CLAIM_FETCHED (or CLAIM_FETCH_FAILED → compensating saga)
   ▼
policy: validates LLM output
   │ Local txn: INSERT into policy_decisions
   │ Emit: POLICY_PASSED (or POLICY_BLOCKED → compensating saga)
   ▼
outbound: sends WhatsApp template
   │ Local txn: INSERT into outbound_intents
   │ Emit: OUTBOUND_SENT (or OUTBOUND_FAILED → compensating saga)
```

Each step is independently retriable. Compensation actions handle partial failures.

---

## Reasons

- **Per-service DB autonomy** — each service deploys schema changes without coordination
- **Failure isolation** — one service's outage doesn't block others (events queue)
- **Microservice principle** — loose coupling, eventual consistency
- **2PC is operationally complex** — requires distributed coordinator; brittle at scale
- **Audit ledger doubles as event log** — IRDAI mandate gives us this for free
- **No cross-service FK** means schema migrations are independent

---

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| Cross-service foreign keys | Couples deploy schedules; can't enforce across DBs anyway |
| 2-phase commit (XA) | Complex coordinator; brittle; unnecessary at pilot scale |
| Shared monolithic DB with FKs | Defeats microservice architecture (ADR-DB-02 conflict) |
| Eventually-consistent NoSQL (DynamoDB-style) | Loses ACID per-service; DPDP compliance harder |
| Separate event bus (Kafka, RabbitMQ) | Audit ledger already serves this purpose; adding Kafka = redundant infra |

---

## Consequences

### Positive
- Per-service deploy independence
- Failure isolation
- Aligned with microservice principles
- Audit ledger serves dual purpose (compliance + event bus)

### Negative
- **Eventual consistency** — services may see stale data briefly
- **Compensation logic must be coded** — every saga step needs failure handler
- **No referential integrity at DB level** — apps must validate references
- **Debug complexity** — distributed traces needed for end-to-end view (Loki + Dataroom IDs help)

### Mitigations
- **Dataroom convention** (`gooclaim-shared`) — 6-correlation-IDs propagated across services for tracing
- **Idempotency keys** — every event handler idempotent (FP-21)
- **Compensation actions documented** — per workflow, document all failure paths
- **Audit trail** — every event in `audit_events` with chained signature (ADR-DB-05)

---

## Implementation Pattern

### Local transaction + event emission (atomic via outbox pattern)

```python
async def fetch_claim(tenant_id: str, claim_id: str):
    async with db.begin() as txn:
        # Step 1: Local txn
        claim = await connector_hub.fetch_claim(tenant_id, claim_id)
        cache_row = ClaimCache(
            tenant_id=tenant_id,
            claim_id_hash=hash_identifier(claim_id, IdentifierType.GENERIC, salt),
            payload_redacted=claim.redacted(),
            source_tier=claim.tier,
        )
        db.add(cache_row)
        
        # Step 2: Atomic emit to outbox (same txn)
        await emit_audit_event(
            event_type="CLAIM_FETCHED",
            tenant_id=tenant_id,
            target=cache_row.id,
            session=db,  # Use same session — ensures atomicity
        )
        # txn commits here — both INSERTs together or neither
```

### Compensating saga step

```python
async def workflow_compensate_on_outbound_fail(workflow_run_id):
    """If outbound failed, mark workflow as escalated."""
    async with db.begin():
        run = await db.get(WorkflowRun, workflow_run_id)
        run.status = "ESCALATED"
        run.escalation_reason = "outbound_send_failed"
        
        await emit_audit_event(
            event_type="WORKFLOW_ESCALATED",
            tenant_id=run.tenant_id,
            target=workflow_run_id,
            payload={"reason": "outbound_send_failed"},
        )
```

---

## Cross-Service References (no FKs, but documented)

Even without DB-level FKs, services reference each other's data via opaque IDs:

| Service | References | Stored as | Validated by |
|---------|-----------|-----------|--------------|
| engine | tenant_id (from auth) | `VARCHAR(64)` | `tenant-config /tenants/{id}` lookup |
| outbound | template_id (from template-registry) | `VARCHAR(128)` | template-registry validation at send time |
| policy | run_id (from engine) | `UUID` | App-layer existence check |
| audit | actor_id (from auth) | `VARCHAR(256)` | App-layer (consume event) |

These are **logical references**, not enforced FKs. Trade-off accepted: services must handle "missing reference" gracefully.

---

## Compensation Actions (Documented per workflow)

Per-workflow compensation logic in `gooclaim-engine/docs/`:

| Workflow | Failure step | Compensation |
|----------|--------------|--------------|
| RW1 claim status | truth fetch fails | Retry with fallback tier (API → Feed → RPA) |
| RW1 claim status | policy blocks output | Escalate to human; emit `POLICY_BLOCKED` |
| RW2 pending docs | doc upload timeout | Send reminder; escalate after 24h |
| RW2 pending docs | connector-hub fails | Retry exponential backoff; escalate after 5 attempts |
| RW3 query reason | KB miss | Escalate to human; emit `KB_MISS` |

---

## Verification

Per service `docs/05-database.md`:

- [ ] No FK references to other service DBs (grep audit)
- [ ] All cross-service references stored as opaque IDs (UUID/string)
- [ ] All state changes emit audit events (paired with local txn)
- [ ] Compensation paths documented per workflow

CI test:

```python
def test_no_cross_service_fks():
    """No FKs reference other service DBs."""
    for table in metadata.tables.values():
        for fk in table.foreign_keys:
            assert fk.target_fullname.startswith(table.schema or "public")
```

---

## References

- ADR-DB-02 — Per-service DB
- `gooclaim-shared/src/gooclaim_shared/audit/emitter.py` — event emission helper
- `gooclaim-shared/middleware/dataroom.py` — correlation ID propagation
- `gooclaim-audit/docs/05-database.md` — audit_events schema
- `Gooclaim-Sheets/Gooclaim-DB-Design.md` — saga pattern in cross-cutting rules
