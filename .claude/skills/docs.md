---
description: Generate the complete Gooclaim standard documentation suite for the current service. Reads src/, git log, CLAUDE.md, and layer rules before writing. P0/P1 = fully generated, P2/P3 = skeleton with TODOs. Usage: /docs | /docs 00-overview | /docs all
---

# /docs — Generate Service Documentation

When this skill is invoked, generate the complete documentation structure for the current Gooclaim service.

## How to invoke

```
/docs               → scaffold ALL missing doc files
/docs all           → same as above
/docs 00-overview   → generate only that one file
/docs readme        → generate only README.md
```

- Argument matches any part of the filename: `03`, `apis`, `03-apis` all work
- **Never overwrite existing files** — skip any file that already exists

---

## Step 0 — Read first (mandatory, always)

Before generating any file, read ALL of the following:

```
CLAUDE.md                         # layer identity, rules, architecture position
.claude/rules/l{N}-*.md           # layer-specific rules (if present)
src/ or app/                      # actual code — services, routes, models, config
git log --oneline -30             # recent commits — derive CHANGELOG entries
git log --oneline --all | wc -l   # total commit count
```

Also read any existing docs that are present — use them to avoid contradictions.

From this reading, extract:
- **Layer number** (L0–L7) and name
- **Service name** (from pyproject.toml / package.json)
- **All endpoints** (from routes/)
- **All env vars** (from config.py / settings.ts)
- **All DB models / Redis keys** (from models/, migrations/)
- **External systems** (from services/, connectors/)
- **Key architectural decisions** made (from commit messages + code structure)

---

## Step 1 — File list to generate

Create any of these that don't already exist:

```
README.md              P0
CHANGELOG.md           P1
CONTRIBUTING.md        P1
GLOSSARY.md            P1

docs/
├── 00-overview.md     P0
├── 01-architecture.md P0
├── 02-components.md   P0
├── 03-apis.md         P1
├── 04-data.md         P1
├── 05-configuration.md P1
├── 06-deployment.md   P2
├── 07-operations.md   P2
├── 08-testing.md      P1
├── 09-development.md  P1
├── 10-adr/
│   ├── 001-*.md       P1  (min 2 ADRs — derive from code decisions)
│   └── 002-*.md       P1
├── 11-security.md     P0
└── 12-integrations.md P1
```

**P0/P1** = generate fully from what you read. No TODOs — fill every section.
**P2/P3** = generate skeleton: section headers + `[TODO: <specific hint>]` placeholders.

---

## Step 2 — Content rules per file

### README.md (P0)

```markdown
# {service-name}

> {one sentence: what this service does in the Gooclaim system}

**Layer:** L{N} — {Layer Name}
**Stack:** {Python 3.12 / FastAPI | Node 20 / ...}
**Status:** {Active / In Development}

[![CI](https://...)]  [![Coverage](badges/coverage.svg)]

## What it does

{2-3 sentences from 00-overview}

## Quick start

\`\`\`bash
{exact commands from CLAUDE.md or pyproject.toml to install + run locally}
\`\`\`

## Documentation

| Doc | Description |
|-----|-------------|
| [Overview](docs/00-overview.md) | Purpose, scope, system position |
| [Architecture](docs/01-architecture.md) | Internal flow, design decisions |
| [API Reference](docs/03-apis.md) | All endpoints |
| [Configuration](docs/05-configuration.md) | Env vars |
| [Security](docs/11-security.md) | PHI, DPDP, IRDAI |

## Related services

{list upstream + downstream services with links to their repos}
```

---

### CHANGELOG.md (P1)

Use Keep a Changelog format. Derive entries from `git log`.

```markdown
# Changelog

All notable changes to {service-name} are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]

### Added
{list from recent commits with feat: prefix}

### Fixed
{list from recent commits with fix: prefix}

## [0.1.0] - {date of first commit}

### Added
- Initial project scaffold
{other initial items from git log}
```

---

### CONTRIBUTING.md (P1)

```markdown
# Contributing to {service-name}

## Branch rules

- Working branch: `develop`
- Never commit directly to `main`
- Branch naming: `feat/{ticket}-{short-desc}` | `fix/{ticket}-{short-desc}`

## Local setup

{copy from 09-development.md quick start}

## Commit format

\`\`\`
feat: add X
fix: resolve Y
docs: update Z
chore: bump deps
\`\`\`

## PR process

1. Branch off `develop`
2. Write tests (minimum 80% coverage)
3. Run `{test command}` locally — must pass
4. Open PR against `develop`
5. Complete PR checklist (see CLAUDE.md)

## PR checklist

{copy checklist from CLAUDE.md verbatim}

## Code conventions

{copy from CLAUDE.md Code Conventions section}
```

---

### GLOSSARY.md (P1)

Include every term relevant to this layer. Always include the core Gooclaim terms + layer-specific ones.

**Always include:**
- `InteractionEvent` — contract from gooclaim-shared, emitted by L0, consumed by L1
- `OutboundIntent` — contract from gooclaim-shared, emitted by L5, consumed by L0
- `AuditEvent` — compliance event, must be emitted for every automated decision
- `OPERATIONAL / RESTRICTED / SUSPENDED` — Operational mode states
- `CONSENT_GIVEN` — DPDP consent gate state, required before any workflow
- `fraud_suspect` — flag set after 5+ NOT_FOUND events, blocks further processing
- `HI / EN / HI_EN` — supported languages (Phase 1)
- `RW1 / RW2 / RW3` — workflow identifiers

**Layer-specific terms:** derive from the code you read (class names, Redis key patterns, DB table names, business logic terms).

---

### docs/00-overview.md (P0)

```markdown
# Overview — {service-name}

## What this service does

{1-2 paragraphs from reading the code. What problem does it solve?}

## What it does NOT do

- {explicit non-responsibility 1}
- {explicit non-responsibility 2}
- {e.g., "Does not call external APIs directly — delegates to L{N}"}

## Position in the L0-L7 stack

\`\`\`
{ASCII diagram showing this service's place, its upstream and downstream}
\`\`\`

| Direction | Service | What it receives/sends |
|-----------|---------|----------------------|
| Receives from | {upstream} | {what} |
| Sends to | {downstream} | {what} |

## Phase 1 scope

{what is in scope for Phase 1 pilot specifically for this service}
{what is deferred to Phase 2+}
```

---

### docs/01-architecture.md (P0)

```markdown
# Architecture — {service-name}

## Internal data flow

\`\`\`
{mermaid or ASCII flowchart — derive from reading the actual code flow}
\`\`\`

## Key design decisions

{For each major decision found in the code, write 1 paragraph explaining:
 - What was decided
 - Why (motivation, constraint)
 - What was rejected}

Link each to a corresponding ADR in docs/10-adr/.

## Layer boundaries enforced here

{list which architectural rules from CLAUDE.md this service enforces, e.g.:
 - "L1 decides, L5 executes — this service never makes workflow decisions"
 - "circuit_breaker state is Redis-backed per tenant"}

## Dependencies

{list internal services this code imports from, e.g. gooclaim-shared contracts}
```

---

### docs/02-components.md (P0)

```markdown
# Components — {service-name}

## File structure

\`\`\`
{actual file tree from src/ — generate with real file names, not placeholders}
\`\`\`

## Entry points

| Entry point | Purpose |
|-------------|---------|
| {main.py / index.ts} | Application startup |
| {routes/} | HTTP route handlers |

## Services / Classes

For each file in services/ (or equivalent), document:

### {ClassName} (`{path/to/file.py}`)

**Purpose:** {one sentence}
**Key method(s):**
- `{method_name}(args) → return` — {what it does}

**Dependencies:** {what it needs injected}
**Raises:** {exception types}
```

---

### docs/03-apis.md (P1)

Document every endpoint found in routes/. For each:

```markdown
## POST /path/to/endpoint

**Purpose:** {what this endpoint does}
**Auth:** {none / internal only / Bearer token}
**Request body:**
\`\`\`json
{exact schema from Pydantic model or type definition}
\`\`\`
**Response (200/202):**
\`\`\`json
{exact schema}
\`\`\`
**Error responses:**
| Status | When |
|--------|------|
| 409 | {condition} |
| 422 | {condition} |
| 503 | {condition} |
```

Also include:
- OpenAPI spec: `GET /docs` (dev/sdx only — disabled in prod)
- Rate limits if any

---

### docs/04-data.md (P1)

```markdown
# Data — {service-name}

## Database tables (PostgreSQL)

For each SQLAlchemy model:

### {table_name}

| Column | Type | PHI? | Description |
|--------|------|------|-------------|
{derive from models/ files}

**Indexes:** {list}
**Retention:** {policy}

## Redis keys

| Key pattern | TTL | Purpose |
|-------------|-----|---------|
{derive from services/ files — look for _KEY_PREFIX and key patterns}

## PHI fields

{List every field that contains PHI (phone, name, claim_id, etc.)}
{Explain how each is protected: hashed / redacted / never stored}

## Contracts (from gooclaim-shared)

{List every contract dataclass this service produces or consumes}
```

---

### docs/05-configuration.md (P1)

```markdown
# Configuration — {service-name}

## Environment variables

Derive from config.py / settings.ts. For every field:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
{e.g.}
| `DATABASE_URL` | Yes | — | PostgreSQL connection string (asyncpg format) |
| `REDIS_URL` | Yes | — | Redis connection string |

Never include actual values. Use `<your-value>` for secrets.

## Config files

{List any YAML/JSON config files, e.g.:}
- `config/languages.yml` — supported languages, detection thresholds
- `config/templates.yml` — approved WhatsApp templates

## Secrets management

All secrets via AWS Secrets Manager through ESO wrapper.
Secret names: {list the secret names used by this service, not the values}
```

---

### docs/06-deployment.md (P2)

Generate skeleton with TODOs:

```markdown
# Deployment — {service-name}

## Docker

\`\`\`bash
# Build
docker build -t {service-name}:{version} .

# Run locally
docker compose up {service-name}
\`\`\`

## Kubernetes

[TODO: add K8s deployment YAML location and key config]

## Deploy flow

[TODO: describe dev → sdx → nprd → prod flow per release.md]

## Environment-specific config

| Env | DATABASE_URL | REDIS_URL | Notes |
|-----|-------------|-----------|-------|
| dev | localhost | localhost | |
| sdx | [TODO] | [TODO] | |
| nprd | [TODO] | [TODO] | |
| prod | [TODO] | [TODO] | |

## Rollback

[TODO: add rollback steps from docs/runbooks/rollback.md]
```

---

### docs/07-operations.md (P2)

Generate skeleton with TODOs:

```markdown
# Operations — {service-name}

## Health checks

\`\`\`bash
curl http://localhost:{port}/health
curl http://localhost:{port}/readiness
\`\`\`

## Common tasks

[TODO: document the 3-5 most common operational tasks for this service]

## Runbooks

- [Deploy](runbooks/deploy.md) — [TODO: create]
- [Rollback](runbooks/rollback.md) — [TODO: create]
- [Incident response](runbooks/incident-response.md) — [TODO: create]

## Known issues

[TODO: document known issues and workarounds]

## Alerts

[TODO: list Grafana alerts and their remediation steps]
```

---

### docs/08-testing.md (P1)

```markdown
# Testing — {service-name}

## Test strategy

- **Unit tests:** all business logic in `services/` — mock external dependencies
- **Integration tests:** every connector (L2, L3, L5) — use real DB/Redis via Docker
- **Coverage gate:** 80% minimum (enforced in CI)

## Run tests

\`\`\`bash
{exact commands from tox.ini / package.json}

# All tests
{tox / pnpm test}

# Single test file
{pytest tests/unit/test_foo.py / jest foo.test.ts}

# With coverage report
{tox -e test}
# Open: htmlcov/index.html
\`\`\`

## Test structure

\`\`\`
tests/
├── unit/       # no real I/O — all services mocked
│   └── test_*.py
└── integration/  # real DB + Redis (Docker Compose)
    └── test_*.py
\`\`\`

## Key test patterns

{derive from reading existing tests — what mocking patterns are used?}
```

---

### docs/09-development.md (P1)

```markdown
# Development — {service-name}

## Prerequisites

- Python 3.12 / Node 20
- Docker + Docker Compose
- {any other tools}

## Local setup

\`\`\`bash
{exact steps — derive from CLAUDE.md commands section}
\`\`\`

## Running locally

\`\`\`bash
{derive from CLAUDE.md or pyproject.toml}
\`\`\`

## Branch + commit conventions

{copy from CONTRIBUTING.md}

## Adding a new endpoint

1. Add route in `routes/{name}.py`
2. Register in `main.py`
3. Add unit tests in `tests/unit/test_routes_{name}.py`
4. Document in `docs/03-apis.md`

## Adding a new service

1. Create `services/{name}.py` with typed class
2. Add factory function to `dependencies.py`
3. Add unit tests in `tests/unit/test_{name}.py`
```

---

### docs/10-adr/ (P1)

Generate **at least 2 ADRs** from the architectural decisions you identified in the code.

How to find decisions to write ADRs for:
- Any `#` comment in code explaining "why not X" or "decision: use Y"
- Commit messages starting with "feat:" that imply a design choice
- Any non-obvious pattern (e.g., "why Redis SET NX for dedup instead of DB?")
- Any choice in `CLAUDE.md` that this service implements (e.g., "circuit_breaker Redis-backed")

Use format: `docs/10-adr/001-{kebab-title}.md`

ADR template:
```markdown
# ADR-001: {Title}

**Date:** {YYYY-MM}
**Status:** Accepted

---

## Context

{What was the problem? What constraints existed?}

## Decision

{One clear sentence.}

## Reasons

- {Reason 1}
- {Reason 2}

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| {Alt 1} | {Reason} |

## Consequences

- {What changes}
- {Trade-offs}
```

---

### docs/11-security.md (P0)

```markdown
# Security — {service-name}

## PHI handling

| Field | Where it appears | How protected |
|-------|-----------------|---------------|
{e.g., phone | from_phone in RawMessage | never logged; hashed via PhoneService before storage}

**Rule:** Never log raw phone, name, or claim_id. Only hashed versions in logs.

## DPDP compliance

{Which DPDP touchpoints does this service enforce?}
- Consent gate: {where is CONSENT_GIVEN checked?}
- Data erasure: {which endpoint/mechanism handles deletion requests?}
- Retention: {how long is data kept and how is it purged?}

## IRDAI requirements

{What IRDAI audit requirements apply to this layer?}
- Audit events: {what automated decisions emit AuditEvent?}
- 7-year retention: {which data must be kept?}

## Secrets this service uses

(Names only — never values)
{list from config.py required fields that are secrets}

## L6 Policy Gate

{Does this service call L6? When? For which outputs?}
```

---

### docs/12-integrations.md (P1)

For each external system found in the code (services/, http clients, DB connections):

```markdown
# Integrations — {service-name}

## {External System Name}

**Purpose:** {what this service uses it for}
**Protocol:** {HTTP / gRPC / Redis pub-sub / PostgreSQL / BullMQ}
**Auth:** {Bearer token / API key / IAM / none}
**Rate limits:** {if applicable}
**Circuit breaker:** {yes/no — Redis-backed per tenant? or none?}
**Connector class:** `{ClassName}` in `{path/to/file.py}`
**Phase:** Phase 1 / Phase 2+

{Repeat for each integration}
```

---

## Step 3 — After generating all files

Tell the user:
1. Which files were created (with paths)
2. Which files were skipped (already existed)
3. Which P2/P3 files need TODO items filled in
4. Suggest next step: `/new-adr` if key decisions need deeper documentation

---

## Rules

- **Never overwrite** an existing file — skip it and note it was skipped
- **Never fabricate** specifics — if a field is unknown, write `[TODO: fill in]`
- **Never include actual secrets** — use `<your-value>` or `[TODO: get from AWS Secrets Manager]`
- **Always derive from code** — don't guess at endpoints, models, or config; read them
- PHI fields: flag them explicitly in every file where they appear
- Emit all files in creation order: root files first, then docs/00 → docs/12
