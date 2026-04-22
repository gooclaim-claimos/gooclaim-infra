# Runbook: Deploy

> Use this when deploying any Gooclaim service to any environment.

---

## Deploy Flow Overview

```
develop merge → auto → dev
manual trigger → sdx
main merge → auto → nprd
manual trigger + approval → prod
```

---

## Dev Deploy (Automatic)

Triggered automatically on every merge to `develop`.

No manual steps needed. Check status:
```
GitHub → Actions → Deploy workflow → dev
```

---

## SDX Deploy (Manual)

```
GitHub → Actions → [service repo] → Deploy → Run workflow
Environment: sdx
```

No approval required. Use sdx for shared team testing before raising a PR to main.

---

## NPRD Deploy (Automatic)

Triggered automatically on every merge to `main`.

Verify after auto-deploy:
```bash
kubectl get pods -n gooclaim-nprd
kubectl rollout status deployment/<service> -n gooclaim-nprd
```

---

## Prod Deploy (Manual + Approval)

**Only after nprd verification is complete.**

### Step 1 — nprd verification

- [ ] RW1 happy path end-to-end (claim status returns correctly)
- [ ] RW2 Temporal workflow starts, waits, resumes on upload
- [ ] RW3 KB lookup returns correct template
- [ ] SUSPENDED mode halts all L5 outbound
- [ ] Audit events appearing in audit ledger
- [ ] L7 metrics healthy

### Step 2 — Trigger prod deploy

```
GitHub → Actions → [service repo] → Deploy → Run workflow
Environment: prod
→ GitHub pauses for approval
→ Click Approve
→ Deploy starts (~2-3 min)
```

### Step 3 — Verify prod

```bash
kubectl rollout status deployment/<service> -n gooclaim-prod --timeout=120s
```

Smoke test — RW1 with a test claim_id via WhatsApp sandbox.

---

## Secrets Required Per Environment

| Secret | Where set |
|--------|-----------|
| `KUBE_CONFIG` | GitHub → Settings → Environments → [env] → Secrets |
| `GHCR_TOKEN` | GitHub → Settings → Environments → [env] → Secrets |

Application secrets (Azure OAI, CMS creds) → AWS Secrets Manager via ESO. Never in GitHub.

---

## If Deploy Fails

1. Check GitHub Actions logs for the failed step
2. If Docker build fails → `docker build .` locally to reproduce
3. If kubectl fails → check `KUBE_CONFIG` secret is valid and not expired
4. If rollout hangs → `kubectl describe pod -n gooclaim-<env>` for pod events

If prod is affected → see `runbooks/rollback.md` immediately.
