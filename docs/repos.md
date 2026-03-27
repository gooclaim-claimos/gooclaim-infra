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
[ ] gooclaim-infra mein se scaffold karo:
    cd gooclaim-infra
    bash scripts/setup-service.sh gooclaim-<service>
[ ] cd ../gooclaim-<service>
[ ] CLAUDE.md mein layer-specific context fill karo
[ ] .env.example se .env banao, values fill karo
[ ] git init && git remote add origin https://github.com/gooclaim-claimos/gooclaim-<service>.git
[ ] git checkout -b main && git add . && git commit -m "chore: initial project setup"
[ ] git push -u origin main
[ ] git checkout -b develop && git push -u origin develop
[ ] Branch protection rules set karo (main + develop)
[ ] 4 environments banao: dev, sdx, nprd, prod
[ ] KUBE_CONFIG + GHCR_TOKEN secrets add karo har environment mein
```

---

## Service Repo Structure

```
gooclaim-{service}/
├── src/
│   └── {service}/
│       ├── __init__.py
│       ├── main.py          ← FastAPI app + /health
│       ├── config.py        ← Pydantic settings (reads .env)
│       ├── routes/          ← API route handlers
│       ├── services/        ← Business logic
│       ├── models/          ← Pydantic request/response models
│       └── connectors/      ← External system connectors
├── migrations/              ← DB migrations (alembic)
├── tests/
│   ├── conftest.py          ← Shared pytest fixtures
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
│   ├── hooks/
│   │   └── check-no-secrets.sh
│   ├── rules/
│   │   └── l{n}-{layer}.md
│   ├── skills/              ← /docs /test /new-adr /session-end
│   └── settings.json
├── badges/
│   └── coverage.svg
├── docs/                    ← Generated via /docs skill
├── Dockerfile
├── docker-compose.yml       ← Local dev (postgres + redis)
├── .dockerignore
├── tox.ini
├── pyproject.toml
├── .gitignore
├── .env.example
├── CLAUDE.md
├── CLAUDE_SESSION.md
└── README.md
```
