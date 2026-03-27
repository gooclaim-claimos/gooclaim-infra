# Gooclaim — Repo Registry
> service-name = GitHub repo name = Docker image name = K8s deployment name
> Naya repo banao → yahan add karo

---

## Phase 1 — Active Repos

| Repo | Layer | service-name in ci.yml | Sprint |
|------|-------|----------------------|--------|
| gooclaim-infra | — | — (master, no CI caller) | Now |
| gooclaim-shared | — | gooclaim-shared | Now |
| gooclaim-knowledge | L3 | gooclaim-knowledge | Sprint 3 |
| gooclaim-policy | L6 | gooclaim-policy | Sprint 3 |
| gooclaim-truth | L2 | gooclaim-truth | Sprint 4 |
| gooclaim-gateway | L0 | gooclaim-gateway | Sprint 5 |
| gooclaim-engine | L1 | gooclaim-engine | Sprint 5 |
| gooclaim-outbound | L5 | gooclaim-outbound | Sprint 6 |
| gooclaim-audit | — | gooclaim-audit | Sprint 6 |
| gooclaim-observe | L7 | gooclaim-observe | Sprint 7 |
| gooclaim-learning | L4 | gooclaim-learning | Sprint 7 |

## Phase 2 — Future Repos

| Repo | Layer | Notes |
|------|-------|-------|
| gooclaim-voice | L0 voice | Voice Gateway — Exotel/Twilio |
| gooclaim-vault | — | Secrets Vault wrapper |
| gooclaim-access | — | RBAC service |
| gooclaim-console | — | Internal UI |
| gooclaim-portal | — | TPA portal UI |

---

## New Repo Checklist

```
[ ] GitHub: gooclaim-claimos org → New repo → Private → blank
[ ] docs/repos.md mein add karo (this file)
[ ] templates/ se copy karo:
    → .github/workflows/ci.yml    (service-name update karo)
    → .github/workflows/deploy.yml (service-name update karo)
    → .github/CODEOWNERS
    → .github/PULL_REQUEST_TEMPLATE/default.md
    → .claude/ (rules + settings.json)
    → tox.ini, pyproject.toml, .gitignore
    → CLAUDE.md (layer-specific content fill karo)
    → CLAUDE_SESSION.md
[ ] Branch protection: main + develop
[ ] develop branch banao
[ ] 4 environments: dev, sdx, nprd, prod
```

---

## Service Repo Structure

```
gooclaim-{service}/
├── src/
│   └── {service}/
│       ├── __init__.py
│       ├── main.py
│       ├── routes/
│       ├── services/
│       └── models/
├── tests/
│   ├── unit/
│   └── integration/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   └── deploy.yml
│   ├── PULL_REQUEST_TEMPLATE/
│   │   └── default.md
│   └── CODEOWNERS
├── .claude/
│   ├── rules/
│   │   └── l{n}-{layer}.md
│   └── settings.json
├── Dockerfile
├── tox.ini
├── pyproject.toml
├── .gitignore
├── CLAUDE.md
├── CLAUDE_SESSION.md
└── README.md
```
