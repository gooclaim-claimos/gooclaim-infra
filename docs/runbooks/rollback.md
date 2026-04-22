# Runbook: Rollback

> Use this when a deploy has caused issues and you need to revert quickly.

---

## When to Rollback

- Users getting error responses from WhatsApp
- L6 Policy Gate passing responses it should be blocking
- PHI appearing in logs (CRITICAL — rollback immediately)
- Audit events not being emitted
- Service crash loop in prod

---

## Quick Rollback (< 5 min)

### Step 1 — Find the previous working SHA

```bash
# Check recent images in GHCR
# GitHub → Packages → gooclaim-claimos/<service> → Recent tags
# OR check previous successful deploy in Actions logs
```

### Step 2 — Rollback the deployment

```bash
# Replace <service> and <previous-sha>
kubectl set image deployment/<service> \
  <service>=ghcr.io/gooclaim-claimos/<service>:<previous-sha> \
  -n gooclaim-prod

kubectl rollout status deployment/<service> -n gooclaim-prod --timeout=120s
```

### Step 3 — Verify rollback

```bash
kubectl get pods -n gooclaim-prod
# All pods should be Running, not CrashLoopBackOff
```

Smoke test: RW1 on prod with test claim_id.

---

## If kubectl Rollback Fails

Use Kubernetes built-in rollback:

```bash
kubectl rollout undo deployment/<service> -n gooclaim-prod
kubectl rollout status deployment/<service> -n gooclaim-prod --timeout=120s
```

---

## Emergency: SUSPENDED Mode (Halt All Outbound)

If the issue is with L5 outbound (wrong messages being sent):

```bash
# Set Operational Mode to SUSPENDED — stops all L5 outbound immediately
# This is a Redis key per tenant
redis-cli SET gooclaim:operational_mode:global SUSPENDED

# Verify
redis-cli GET gooclaim:operational_mode:global
# → "SUSPENDED"
```

All L5 execution halts within seconds. Users get no response (better than wrong response).

Resume when safe:
```bash
redis-cli SET gooclaim:operational_mode:global OPERATIONAL
```

---

## Circuit Breaker Reset (if L2 CMS was involved)

After rollback, if L2 CMS connector was affected, verify circuit breaker state:

```bash
# Check state
redis-cli GET gooclaim:circuit_breaker:<tenant_id>:cms
# CLOSED = normal | OPEN = using fallback feed | HALF_OPEN = testing recovery

# Manual reset only if CMS is confirmed healthy
redis-cli SET gooclaim:circuit_breaker:<tenant_id>:cms CLOSED
```

---

## After Rollback

- [ ] Document what caused the issue in `CLAUDE_SESSION.md` → Known Issues table
- [ ] Create hotfix branch: `git checkout -b hotfix/<service>-<description>`
- [ ] Fix → CI pass → PR to main → nprd verify → prod deploy
- [ ] Add regression test to prevent recurrence
