# gooclaim-infra

Central infrastructure repository for Gooclaim — CI/CD pipelines, service templates, and architecture documentation.

## What's in here

| Directory | Purpose |
|-----------|---------|
| `.github/workflows/` | Reusable CI and deploy workflows — all service repos call these |
| `templates/` | Scaffold for every new service repo |
| `docs/` | Architecture, repo registry, runbooks, ADRs |
| `scripts/` | Utility scripts |

## Creating a new service repo

```bash
bash scripts/setup-service.sh gooclaim-<service>
```

Then follow the printed steps — branch protection and environments still need to be set on GitHub manually.

## Repo registry

See [docs/repos.md](docs/repos.md) for the full list of Phase 1 and Phase 2 repos.

## Architecture

See [docs/architecture.md](docs/architecture.md) for the layer → repo mapping and data flow.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch strategy, commit conventions, and PR rules.
