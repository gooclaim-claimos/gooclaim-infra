# Runbook: Incident Response

> Use this when something goes wrong in production.

---

## Severity Levels

| Level | Description | Response Time | Example |
|-------|-------------|---------------|---------|
| P0 | PHI leak / IRDAI breach | Immediate | Phone/name/claim_id in plaintext logs |
| P0 | Complete service outage | Immediate | All WhatsApp messages failing |
| P1 | L6 Policy Gate bypassed | < 15 min | LLM output reaching users unchecked |
| P1 | Audit events not emitting | < 15 min | BullMQ audit queue dead |
| P2 | Single workflow degraded | < 1 hour | RW2 Temporal workflows not starting |
| P3 | Performance degradation | < 4 hours | Response times > 5s (SLA is 3s) |

---

## P0: PHI Leak — Immediate Steps

1. **SUSPEND immediately:**
   ```bash
   redis-cli SET gooclaim:operational_mode:global SUSPENDED
   ```

2. **Identify scope:** Which logs? Which service? How many records?
   ```bash
   kubectl logs deployment/<service> -n gooclaim-prod | grep -i "phone\|name\|claim_id"
   ```

3. **Rotate credentials** if PHI appeared in external logs (Datadog, Sentry, etc.)

4. **Notify:** Inform legal/compliance team — IRDAI breach protocol may apply

5. **Fix:** Hotfix branch → redact PHI from logs → verify with `grep` → deploy

6. **Resume:**
   ```bash
   redis-cli SET gooclaim:operational_mode:global OPERATIONAL
   ```

7. **Document:** Full incident report in `CLAUDE_SESSION.md` Known Issues

---

## P1: L6 Policy Gate Bypassed

1. **SUSPEND immediately** (see above)
2. Check L6 service health: `kubectl get pods -n gooclaim-prod | grep policy`
3. Check if L6 is reachable from L1: `kubectl logs deployment/gooclaim-engine -n gooclaim-prod | grep policy`
4. If L6 is down → fix L6 first, verify it's healthy, then RESUME
5. Audit all messages sent during the window → check audit ledger

---

## P1: Audit Events Not Emitting

1. Check BullMQ (Redis): `redis-cli LLEN gooclaim:audit:queue`
2. Check audit worker: `kubectl logs deployment/gooclaim-audit -n gooclaim-prod`
3. If queue is backing up → scale audit worker: `kubectl scale deployment/gooclaim-audit --replicas=3 -n gooclaim-prod`
4. If Redis is down → this is a P0 — all services are affected

---

## P2: Single Workflow Degraded

### RW1 not responding
```bash
kubectl logs deployment/gooclaim-engine -n gooclaim-prod | grep RW1
kubectl logs deployment/gooclaim-truth -n gooclaim-prod   # L2 issue?
```

### RW2 Temporal workflows not starting
```bash
# Check Temporal worker
kubectl logs deployment/gooclaim-engine -n gooclaim-prod | grep temporal
# Check Temporal server health
```

### RW3 KB lookup failing
```bash
kubectl logs deployment/gooclaim-knowledge -n gooclaim-prod
# Check pgvector connection
# Check Langfuse for L3 LLM call failures
```

### L6 and L3 C4 both failing simultaneously
Both share the same Guardrails AI Docker container — likely a container issue:
```bash
kubectl get pods -n gooclaim-prod | grep guardrails
kubectl logs <guardrails-pod> -n gooclaim-prod
# Restart container if stuck on cold start
kubectl rollout restart deployment/guardrails-ai -n gooclaim-prod
```

---

## Circuit Breaker States

If L2 CMS connector is failing:

```
CLOSED → normal operation
OPEN → CMS unreachable, falling back to CSV/SFTP feed
HALF_OPEN → testing recovery
```

Check state:
```bash
redis-cli GET gooclaim:circuit_breaker:<tenant_id>:cms
```

Manual reset (only if CMS is confirmed healthy):
```bash
redis-cli SET gooclaim:circuit_breaker:<tenant_id>:cms CLOSED
```

---

## Escalation Path

```
On-call engineer
  → If P0/P1: Immediately loop in Mayank
  → If IRDAI breach suspected: Legal/compliance team within 1 hour
  → If TPA-side issue: TPA contact (see internal contacts doc)
```

---

## Post-Incident

- [ ] Root cause identified
- [ ] Fix deployed and verified
- [ ] Known Issues table in `CLAUDE_SESSION.md` updated
- [ ] Regression test added
- [ ] If IRDAI-relevant: incident report filed
