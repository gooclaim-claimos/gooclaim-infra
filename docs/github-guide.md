# Gooclaim — GitHub Complete Guide
> Version: 1.0 | March 2026  
> Yeh file padho pehle. Sab kuch yahan hai.  
> Confuse ho? Yahan dekho. Answer milega.

---

## Table of Contents

1. [Organization Structure](#1-organization-structure)
2. [Repo List](#2-repo-list)
3. [Branch Strategy](#3-branch-strategy)
4. [Branch Protection Rules](#4-branch-protection-rules)
5. [CI Pipeline](#5-ci-pipeline)
6. [Deploy Pipeline](#6-deploy-pipeline)
7. [Environments](#7-environments)
8. [Daily Workflow](#8-daily-workflow)
9. [PR Rules](#9-pr-rules)
10. [Secrets Setup](#10-secrets-setup)
11. [Naya Repo Kaise Banayein](#11-naya-repo-kaise-banayein)
12. [Quick Reference](#12-quick-reference)

---

## 1. Organization Structure

```
github.com/gooclaim          ← GitHub Organization (Team plan, $4/user/month)
│
├── gooclaim-infra           ← MASTER repo — CI/CD, K8s, Terraform
├── gooclaim-shared          ← Shared types, utils, contracts
│
├── gooclaim-gateway         ← Service: WhatsApp in (L0)
├── gooclaim-engine          ← Service: Workflows RW1/RW2/RW3 (L1)
├── gooclaim-truth           ← Service: CMS connector (L2)
├── gooclaim-knowledge       ← Service: RAG / KB (L3)
├── gooclaim-policy          ← Service: Guardrails / PHI (L6)
├── gooclaim-outbound        ← Service: WhatsApp out (L5)
├── gooclaim-audit           ← Service: Audit ledger (L7)
└── gooclaim-observe         ← Service: Observability (L7)
```

**Important:**
- `gooclaim-infra` = sabka baap. CI/CD rules yahan hain. Kisi service repo mein CI update karna ho? `gooclaim-infra` mein karo — sab ko automatically mil jaata hai.
- `gooclaim-shared` = common code. Har service yahan se types aur utils import karti hai. Duplicate mat karo.
- Har service repo apna alag deploy cycle hai. Ek service down ho toh baaki chalti hain.

---

## 2. Repo List

### Phase 1 — Abhi banao (Sprint ke hisaab se)

| Repo | Kya karta hai | Sprint | Status |
|------|--------------|--------|--------|
| gooclaim-infra | CI/CD master, K8s, Terraform | Now | ⬜ |
| gooclaim-shared | Types, utils, contracts | Now | ⬜ |
| gooclaim-knowledge | RAG, KB, Haystack | Sprint 3 | ⬜ |
| gooclaim-policy | Policy gate, Guardrails AI, PHI | Sprint 3 | ⬜ |
| gooclaim-truth | CMS connector, circuit breaker | Sprint 4 | ⬜ |
| gooclaim-gateway | WhatsApp webhook, lang detect | Sprint 5 | ⬜ |
| gooclaim-engine | RW1, RW2, RW3, Temporal | Sprint 5 | ⬜ |
| gooclaim-outbound | WhatsApp templates, retry | Sprint 6 | ⬜ |
| gooclaim-audit | BullMQ queues, 7yr retention | Sprint 6 | ⬜ |
| gooclaim-observe | Metrics, alerting, dashboards | Sprint 7 | ⬜ |

### Phase 2 — Baad mein banao

| Repo | Kya karta hai |
|------|--------------|
| gooclaim-voice | Voice gateway |
| gooclaim-vault | Secrets vault wrapper |
| gooclaim-access | RBAC service |
| gooclaim-console | Internal console UI |
| gooclaim-portal | TPA portal UI |

---

## 3. Branch Strategy

### Branch Types

```
main          ← Production-ready code. Protected. Direct push allowed nahi.
develop       ← Integration branch. Protected. Feature branches yahan merge hoti hain.
│
├── feat/<service>-<description>     ← Naya feature
├── fix/<service>-<description>      ← Bug fix
├── chore/<description>              ← Deps, config, tooling
├── docs/<description>               ← Sirf documentation
├── test/<service>-<description>     ← Sirf tests
└── hotfix/<description>             ← Emergency fix (prod mein bug)
```

### Naming Rules

- Lowercase only — no uppercase, no spaces
- Hyphens use karo, underscores nahi
- Service name prefix mandatory for `feat`, `fix`, `test`
- Description 40 characters se kam

**Examples — sahi:**
```
feat/gateway-whatsapp-webhook-handler
feat/engine-rw2-temporal-workflow
fix/engine-session-ttl-reset
fix/policy-phi-in-error-logs
chore/upgrade-fastapi-0-111
docs/openapi-engine-endpoints
hotfix/policy-phi-plaintext-leak
test/truth-cms-fallback-chain
```

**Examples — galat:**
```
feature/WhatsApp          ← uppercase, no service prefix
bugfix_session            ← underscore, wrong prefix
fix/l1-session-ttl        ← L1 internal naming, not here
my-branch                 ← no prefix, no service
```

### Merge Strategy

| From | To | Method | Why |
|------|----|--------|-----|
| `feat/*` | `develop` | Squash merge | Develop history clean rahti hai |
| `develop` | `main` | Merge commit | Develop history preserve hoti hai main pe |
| `hotfix/*` | `main` | Squash merge | Fast, clean |
| `hotfix/*` | `develop` | Cherry-pick | Same fix develop mein bhi chahiye |

---

## 4. Branch Protection Rules

GitHub pe jaao: **Settings → Branches → Add branch ruleset**

### `main` — Strictest

| Setting | Value |
|---------|-------|
| Require PR before merging | ✅ On |
| Required approvals | 1 |
| Dismiss stale reviews on new push | ✅ On |
| Require CODEOWNERS review | ✅ On |
| Require status checks to pass | ✅ On |
| Required checks | `lint`, `typecheck`, `security`, `test`, `docker-build` |
| Require branches to be up to date | ✅ On |
| Require linear history (rebase only) | ✅ On |
| Allow bypass | ❌ Off — koi bypass nahi kar sakta |

### `develop` — Relaxed

| Setting | Value |
|---------|-------|
| Require PR before merging | ✅ On |
| Required approvals | 1 |
| Dismiss stale reviews on new push | ✅ On |
| Require status checks to pass | ✅ On |
| Required checks | `lint`, `typecheck`, `security`, `test` |
| Require branches to be up to date | ✅ On |
| Allow bypass | ❌ Off |

> **Note:** `docker-build` develop pe required nahi — CI mein chalta hai but merge block nahi karta. `main` pe mandatory hai.

### CODEOWNERS File

`.github/CODEOWNERS` banao har repo mein:

```
# Sab PRs require review from core team
* @gooclaim/core-team

# Sensitive files — extra caution
src/policy/           @gooclaim/core-team
src/audit/            @gooclaim/core-team
config/languages.yml  @gooclaim/core-team
```

---

## 5. CI Pipeline

### Kaise kaam karta hai

Har service repo mein sirf ek 15-line file hoti hai: `.github/workflows/ci.yml`

Yeh file khud kuch nahi karti — sirf `gooclaim-infra` ko call karti hai:

```yaml
jobs:
  ci:
    uses: gooclaim/gooclaim-infra/.github/workflows/_reusable-ci.yml@main
    with:
      service-name: gooclaim-engine    # ← sirf yeh change hota hai har repo mein
      coverage-threshold: 80
```

**Baaki sab logic `gooclaim-infra/_reusable-ci.yml` mein hai.**

Agar koi CI rule change karna ho — sirf `gooclaim-infra` update karo. Sab repos ko automatically mil jaata hai.

### CI Jobs — Sequence

```
PR open hota hai
       ↓
  1. LINT (ruff)
     ~10 seconds
     Fail → PR block, baaki jobs nahi chalte
       ↓
  2a. TYPE CHECK (pyright)    2b. SECURITY SCAN
      parallel chalte hain ←→ bandit + safety + trufflehog
       ↓              ↓
       └──────┬───────┘
              ↓
  3. TEST + COVERAGE (pytest)
     Postgres + Redis spin up hota hai
     Coverage < 80% → PR block
       ↓
  4. DOCKER BUILD CHECK
     Build hota hai — push nahi
     Verify karta hai image banta hai
       ↓
  Sab green → Merge allowed
```

### Coverage Rules

- Minimum: **80%** — isse kam = CI red = PR block
- Report automatically PR pe comment ke roop mein aata hai
- HTML report artifact mein save hota hai (Actions tab → Artifacts)
- `src/migrations/` aur `__init__.py` coverage se exclude hain

### Security Scan — Teen Layers

| Tool | Kya check karta hai |
|------|---------------------|
| `bandit` | Code-level vulnerabilities — SQL injection, hardcoded secrets, unsafe functions |
| `safety` | Python dependencies mein known CVEs |
| `trufflehog` | Git history mein leaked secrets, API keys, passwords |

> TruffleHog poori git history scan karta hai, sirf current code nahi. Ek baar bhi secret commit hua — woh pakad leta hai.

---

## 6. Deploy Pipeline

### Kaise kaam karta hai

CI ke jaisa — har service repo mein sirf ek caller file `.github/workflows/deploy.yml`. Actual logic `gooclaim-infra/_reusable-deploy.yml` mein.

### Deploy Flow

```
develop branch mein merge
        ↓
   Auto deploy → dev
        ↓
   Manual trigger → sdx (sandbox)
        ↓
main branch mein merge
        ↓
   Auto deploy → nprd
        ↓
   Manual trigger → prod
   (1 approver ka wait — GitHub block karta hai)
```

### Trigger Types

| Trigger | Kaise karte hain | Approval |
|---------|-----------------|----------|
| dev deploy | develop mein merge karo | Auto — koi approval nahi |
| sdx deploy | GitHub Actions → Run workflow | Manual trigger hi approval hai |
| nprd deploy | main mein merge karo | Auto — PR approval already hua |
| prod deploy | GitHub Actions → Run workflow → Approve | 1 approver must click Approve |

### Docker Images

Sab images `ghcr.io/gooclaim/` mein push hote hain:

```
ghcr.io/gooclaim/gooclaim-engine:abc123def    ← specific SHA tag
ghcr.io/gooclaim/gooclaim-engine:dev-latest   ← env-latest tag
ghcr.io/gooclaim/gooclaim-engine:nprd-latest
ghcr.io/gooclaim/gooclaim-engine:prod-latest
```

---

## 7. Environments

### Setup — GitHub pe

```
Settings → Environments → New environment
```

Chaar environments banao: `dev`, `sdx`, `nprd`, `prod`

### Environment Settings

| Environment | URL | Protection | Secrets |
|-------------|-----|-----------|---------|
| dev | dev.gooclaim.internal | None | DEV_KUBE_CONFIG |
| sdx | sdx.gooclaim.internal | None | SDX_KUBE_CONFIG |
| nprd | nprd.gooclaim.internal | None | NPRD_KUBE_CONFIG |
| prod | api.gooclaim.in | 1 required reviewer | PROD_KUBE_CONFIG |

### prod Environment — Extra Step

```
Settings → Environments → prod
→ Environment protection rules
→ Required reviewers → apna username add karo
```

Yeh setting ke baad prod deploy ke liye GitHub automatically pause karega aur tumhare approval ka wait karega.

---

## 8. Daily Workflow

### Kaam shuru karte waqt

```bash
# 1. Latest code lo
git checkout develop
git pull origin develop

# 2. CLAUDE_SESSION.md padho — last session kahan ruka tha
# 3. Apna naya session block start karo CLAUDE_SESSION.md mein

# 4. Branch banao
git checkout -b feat/engine-rw1-claim-status
```

### Kaam karte waqt

```bash
# Locally CI chalate raho
tox -e lint          # style check
tox -e typecheck     # type check
tox -e test          # tests + coverage
tox                  # sab ek saath

# Conventional commits use karo
git commit -m "feat(engine): add RW1 claim status workflow skeleton"
git commit -m "test(engine): add unit tests for RW1 happy path"
git commit -m "fix(engine): session TTL not resetting on re-consent"
```

### Kaam khatam karte waqt

```bash
# 1. Final tox pass karo
tox

# 2. Push karo
git push origin feat/engine-rw1-claim-status

# 3. PR open karo → develop
gh pr create --base develop --title "feat(engine): RW1 claim status workflow"

# 4. CLAUDE_SESSION.md update karo
#    - kya kiya
#    - kya decisions liye
#    - kya bacha
#    - koi blocker

# 5. CLAUDE_SESSION.md commit karo
git add CLAUDE_SESSION.md
git commit -m "docs: session log $(date +%Y-%m-%d) [naam]"
git push
```

### Commit Message Format

```
<type>(<service>): <short description>

Types:
  feat     ← naya feature
  fix      ← bug fix
  chore    ← deps, config, tooling
  docs     ← documentation
  test     ← tests only
  hotfix   ← emergency fix

Examples:
  feat(engine): add RW2 Temporal workflow for pending docs
  fix(gateway): lang detection failing for pure Hindi messages
  chore: upgrade FastAPI to 0.111.0
  test(truth): add CMS fallback chain integration tests
  docs(engine): add OpenAPI spec for workflow endpoints
```

---

## 9. PR Rules

### PR Title

Same format as commit message:

```
feat(engine): RW2 pending docs workflow
fix(policy): PHI appearing in error logs
```

### PR Checklist

PR open karne se pehle yeh sab tick karo:

**Code quality:**
- [ ] `tox` locally pass kiya
- [ ] Koi `any` type introduce nahi kiya
- [ ] Koi `print()` statement nahi (sirf `logger` use karo)
- [ ] Koi hardcoded secret, URL, ya credential nahi

**Gooclaim-specific:**
- [ ] PHI logs mein nahi — phone, name, claim_id plaintext mein nahi
- [ ] Har naya automated decision audit event emit karta hai
- [ ] Consent gate (DPDP) skip nahi hua
- [ ] Workflow version bump hua agar workflow badla

**Tests:**
- [ ] Naye logic ke liye unit tests likhe
- [ ] Naye connector ke liye integration test likha
- [ ] Edge cases cover kiye — NOT_FOUND, timeout, circuit breaker

**Documentation:**
- [ ] `CLAUDE_SESSION.md` update kiya agar koi architectural decision hua
- [ ] OpenAPI spec update kiya agar API change hua

### Review Process

1. PR open karo → CI automatically start hota hai
2. Sab checks green hone ka wait karo (~5-10 minutes)
3. Ek teammate ko review ke liye assign karo
4. Review + 1 approval → Squash merge karo `develop` mein
5. Auto deploy → `dev` environment

---

## 10. Secrets Setup

### Kahan store hote hain

**GitHub Environment Secrets** (per-environment):

```
Settings → Environments → [env] → Environment secrets
```

| Secret | Environment | Value |
|--------|-------------|-------|
| DEV_KUBE_CONFIG | dev | base64 kubeconfig for dev K8s cluster |
| SDX_KUBE_CONFIG | sdx | base64 kubeconfig for sdx K8s cluster |
| NPRD_KUBE_CONFIG | nprd | base64 kubeconfig for nprd K8s cluster |
| PROD_KUBE_CONFIG | prod | base64 kubeconfig for prod K8s cluster |

**kubeconfig ko base64 kaise karein:**
```bash
cat ~/.kube/config | base64 | tr -d '\n'
# Output ko GitHub secret mein paste karo
```

### Application Secrets

Application secrets (Azure OAI key, CMS passwords, etc.) **GitHub mein nahi jate**. Yeh AWS Secrets Manager mein hain — `gooclaim-vault` repo handle karta hai.

### Kya kabhi commit nahi karna

```
❌ API keys
❌ Passwords
❌ .env files
❌ kubeconfig files
❌ Private keys / certificates
❌ Database URLs with credentials
```

TruffleHog CI mein har PR pe yeh check karta hai. Kuch bhi accidentally commit hua → CI red → PR block.

---

## 11. Naya Repo Kaise Banayein

### Step 1 — GitHub pe repo banao

```
github.com/gooclaim → New repository
Name: gooclaim-<service>
Visibility: Private
Initialize: Without README (blank)
```

### Step 2 — Local setup

```bash
# gooclaim-infra clone karo (agar nahi hai)
git clone https://github.com/gooclaim/gooclaim-infra
cd gooclaim-infra

# Setup script chalao
bash setup-service.sh gooclaim-<service>

# Script automatically:
# - Folder structure banata hai (src/, tests/, .github/)
# - Template files copy karta hai
# - service-name update karta hai ci.yml aur deploy.yml mein
```

### Step 3 — Remote connect karo

```bash
cd ../gooclaim-<service>
git init
git remote add origin https://github.com/gooclaim/gooclaim-<service>
git checkout -b main
git add .
git commit -m "chore: initial project setup"
git push -u origin main

# develop branch banao
git checkout -b develop
git push -u origin develop
```

### Step 4 — Branch protection set karo

GitHub pe: **Settings → Branches → Add branch ruleset**

- `main` rules: [Section 4 dekho](#4-branch-protection-rules)
- `develop` rules: [Section 4 dekho](#4-branch-protection-rules)

### Step 5 — REPOS.md update karo

`gooclaim-infra/REPOS.md` mein naya repo add karo.

### Step 6 — CLAUDE.md update karo

Naye repo mein layer-specific rules add karo `.claude/rules/` mein.

---

## 12. Quick Reference

### Koi bhi kaam shuru karte waqt

```bash
git checkout develop && git pull    # latest lo
git checkout -b feat/<service>-<desc>  # branch banao
tox                                 # local mein check karo
```

### CI fail ho raha hai — kya karu

| Error | Fix |
|-------|-----|
| `ruff` lint fail | `tox -e lint` locally chalao, errors fix karo |
| `pyright` type error | `tox -e typecheck` chalao, type hints fix karo |
| Coverage < 80% | Tests likho — `tox -e test` mein dekho kaunsi lines miss hain |
| `bandit` security | Code mein unsafe function use ho raha hai — fix karo |
| `safety` CVE | `pip install --upgrade <package>` karo |
| `trufflehog` secret | Git history mein secret hai — rotate immediately, fir git history clean karo |
| Docker build fail | `docker build .` locally chalao, Dockerfile fix karo |

### Prod mein deploy karna hai

```
1. Sab tests nprd pe pass karein
2. GitHub Actions → gooclaim-<service> → Deploy workflow
3. Environment: prod select karo
4. Run workflow click karo
5. GitHub pause karega — Approve button dikhega
6. Approve karo → Deploy shuru
```

### Hotfix — prod mein urgent bug

```bash
git checkout main
git pull origin main
git checkout -b hotfix/policy-phi-in-logs

# fix karo
tox  # local pass karo

git push origin hotfix/policy-phi-in-logs
# PR → main (1 approval, CI must pass)
# Merge → Auto deploy nprd
# Verify → Manual deploy prod

# develop mein bhi fix chahiye
git checkout develop
git cherry-pick <commit-sha>
git push origin develop
```

---

> Last updated: March 2026  
> Koi question? CLAUDE_SESSION.md mein likho ya team mein poochho.
