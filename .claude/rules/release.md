# Gooclaim — Release Checklist for Claude

Follow this checklist when preparing or reviewing a release.

---

## Pre-Release Checks (All Envs)

- [ ] All CI checks green on `main`: lint, typecheck, security, test, docker-build
- [ ] Coverage ≥ 80% on all changed services
- [ ] TruffleHog scan clean — no secrets in git history
- [ ] No `any` types or missing type hints introduced
- [ ] No PHI in logs confirmed (grep for phone, name, claim_id in log statements)

## Gooclaim-Specific Pre-Release

- [ ] Operational Mode check present in all workflow entry points
- [ ] Consent gate (DPDP) Step 0 verified in all workflow paths
- [ ] L6 Policy Gate on every LLM output — not bypassed anywhere
- [ ] All new automated decisions emit AuditEvent
- [ ] `registry.yml` version bumped for any workflow change
- [ ] `circuit_breaker` state confirmed Redis-backed (not in-memory)
- [ ] `fraud_suspect` flag logic intact (5+ NOT_FOUND → flag set)
- [ ] Templates only — no free-text LLM generation paths added

## Deploy Flow

```
develop merge → auto deploy → dev
manual trigger → sdx (sandbox testing)
main merge → auto deploy → nprd
manual trigger + 1 approver → prod
```

## nprd Verification Before Prod

- [ ] RW1 (claim status) happy path tested end-to-end
- [ ] RW2 (pending docs) Temporal workflow starts and waits correctly
- [ ] RW3 (query reason) KB lookup returns correct template
- [ ] SUSPENDED mode tested — all L5 outbound halts
- [ ] Circuit breaker tested — L2 fallback chain works (API → Feed → RPA)
- [ ] Audit events appearing in audit ledger
- [ ] L7 metrics dashboard showing correct data

## Prod Deploy Steps

```
1. nprd verification complete (above checklist)
2. GitHub Actions → gooclaim-<service> → Deploy workflow
3. Select environment: prod
4. Click Run workflow
5. GitHub pauses → Approve button appears
6. Click Approve → Deploy starts
7. kubectl rollout status confirms healthy
8. Smoke test: RW1 on prod with test claim_id
```

## Rollback

If prod deploy fails or incident detected within 1h:

```bash
# Immediate: revert to previous image
kubectl set image deployment/<service> <service>=ghcr.io/gooclaim-claimos/<service>:<previous-sha> -n gooclaim-prod
kubectl rollout status deployment/<service> -n gooclaim-prod --timeout=120s
```

See `docs/runbooks/rollback.md` for full rollback procedure.

## Post-Release

- [ ] CLAUDE_SESSION.md updated with release notes
- [ ] Known issues table updated
- [ ] Module Checklist status updated
- [ ] Environment Status table updated
