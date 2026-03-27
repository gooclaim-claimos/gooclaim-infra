# Contributing to Gooclaim
> Version: 1.0 | March 2026

---

## Branch Strategy

### Branch Structure

```
main          ← Production-ready code only. Protected. No direct push.
develop       ← Integration branch. Protected. Feature branches merge here.
│
├── feat/<layer>-<description>      ← New feature
├── fix/<layer>-<description>       ← Bug fix
├── chore/<description>             ← Deps, config, tooling
├── docs/<description>              ← Documentation only
├── test/<layer>-<description>      ← Tests only
└── hotfix/<description>            ← Emergency prod fix
```

### Branch Naming Rules

- Lowercase only — no CamelCase, no spaces
- Hyphens, not underscores
- Layer prefix (`l0`–`l7`) mandatory for `feat`, `fix`, `test` branches
- Description under 40 characters

**Correct:**
```
feat/l1-rw2-temporal-workflow
fix/l0-lang-detect-hinglish-edge-case
chore/upgrade-fastapi-0-111
docs/openapi-l1-workflow
hotfix/l6-phi-plaintext-in-logs
test/l2-cms-fallback-chain
```

**Wrong:**
```
feature/WhatsApp          ← uppercase, no layer prefix
bugfix_session            ← underscore, wrong prefix
my-branch                 ← no prefix at all
```

### Merge Strategy

| From | To | Method |
|------|----|--------|
| `feat/*` | `develop` | Squash merge — keeps develop history clean |
| `develop` | `main` | Merge commit — preserves develop history on main |
| `hotfix/*` | `main` | Squash merge |
| `hotfix/*` | `develop` | Cherry-pick |

---

## Commit Message Format

```
<type>(<layer>): <short description>

Types: feat | fix | chore | docs | test | hotfix

Examples:
  feat(l1): add RW2 Temporal workflow for pending docs
  fix(l0): lang detection failing for pure Hindi messages
  chore: upgrade FastAPI to 0.111.0
  test(l2): add CMS fallback chain integration tests
  hotfix(l6): prevent PHI from appearing in error logs
```

---

## PR Rules

### PR Title
Same format as commit message:
```
feat(l1): RW2 pending docs workflow
fix(l6): PHI appearing in error logs
```

### PR Checklist
Before opening a PR, tick all boxes in the PR template. Key items:

- `tox` passes locally
- No `any` types, no `print()` statements
- No hardcoded secrets, URLs, or credentials
- No PHI in logs (phone, name, claim_id as plaintext)
- Every new automated decision emits an audit event
- Consent gate (DPDP) not skipped
- `registry.yml` version bumped if workflow changed

### Review Process

1. PR open → CI automatically starts (~5–10 min)
2. All checks green → assign 1 teammate for review
3. 1 approval + all checks green → Squash merge to `develop`
4. Auto deploy to `dev` environment

---

## Daily Workflow

```bash
# Start of day
git checkout develop && git pull origin develop
git checkout -b feat/l1-rw1-claim-status

# During work — run locally before pushing
tox -e lint        # style check (~10s)
tox -e typecheck   # type check
tox -e test        # tests + coverage
tox                # all at once

# End of day
tox                                              # final pass
git push origin feat/l1-rw1-claim-status
gh pr create --base develop --title "feat(l1): RW1 claim status workflow"
# Update CLAUDE_SESSION.md → commit → push
```

---

## Hotfix Process

```bash
git checkout main && git pull origin main
git checkout -b hotfix/l6-phi-in-logs

# Fix → tox → push
gh pr create --base main --title "hotfix(l6): PHI in error logs"
# 1 approval + CI green → Squash merge to main → auto deploy nprd → manual prod

# Backport to develop
git checkout develop
git cherry-pick <commit-sha>
git push origin develop
```
