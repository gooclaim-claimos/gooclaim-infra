---
description: Generate the complete documentation structure for this Gooclaim service. Scaffolds README, CHANGELOG, GLOSSARY, and docs/00 through docs/12. Never overwrites existing files.
---

# /docs — Generate Service Documentation

When this skill is invoked, generate the complete documentation structure for this Gooclaim service.

## How to invoke

```
/docs
/docs 00-overview
/docs all
```

- No argument or `all` → scaffold ALL missing doc files
- Specific filename → generate only that file

---

## Step 1 — Identify the service

Read these files first to understand which layer/service this is:
- `CLAUDE.md` — layer identity and rules
- `.claude/rules/l{n}-*.md` — layer-specific rules
- `src/` — actual code structure

---

## Step 2 — Scaffold missing files

Create any of these that don't exist yet. Never overwrite existing files.

```
README.md
CHANGELOG.md
GLOSSARY.md
docs/
├── 00-overview.md
├── 01-architecture.md
├── 02-components.md
├── 03-apis.md
├── 04-data.md
├── 05-configuration.md
├── 06-deployment.md
├── 07-operations.md
├── 08-testing.md
├── 09-development.md
├── 10-adr/
├── 11-security.md
└── 12-integrations.md
```

---

## Step 3 — Content rules per file

### README.md
- One-line description of what this service does
- Which layer it is (L0-L7) and its position in the system
- Quick start: how to run locally
- Link to `docs/00-overview.md` for full docs
- Badges: CI status, coverage (from `badges/coverage.svg`)

### CHANGELOG.md
- Standard Keep a Changelog format
- Start with `## [Unreleased]` section
- Never fabricate version history — leave empty sections

### GLOSSARY.md
Include all Gooclaim-specific terms relevant to this layer:
- InteractionEvent, OutboundIntent, AuditEvent, ClaimRequest, KBQuery
- RW1, RW2, RW3
- OPERATIONAL / RESTRICTED / SUSPENDED
- HI, EN, HI_EN
- CONSENT_GIVEN, fraud_suspect
- Layer-specific terms (e.g., for L2: NOT_FOUND, STALE, ICMSConnector)

### docs/00-overview.md
- What this service does (1 paragraph)
- What it does NOT do
- Where it sits in the L0-L7 stack
- Which services it talks to (upstream + downstream)
- Phase 1 scope for this service

### docs/01-architecture.md
- Internal data flow diagram (ASCII or mermaid)
- Key design decisions for this layer
- Link to relevant ADRs in `docs/10-adr/`

### docs/02-components.md
- File/folder structure with explanation
- Key classes and their responsibilities
- Entry points

### docs/03-apis.md
- All FastAPI endpoints (method, path, request, response)
- Error codes — use Gooclaim standard 6 codes for L2: NOT_FOUND, MULTIPLE_MATCH, AUTH_REQUIRED, SOURCE_DOWN, TIMEOUT, STALE
- OpenAPI spec location

### docs/04-data.md
- Pydantic models / DB schemas
- PHI fields — mark clearly which fields are PHI
- Retention policy (audit events = 7yr, session = 24hr, etc.)

### docs/05-configuration.md
- All env vars with description, required/optional, default
- Never include actual values — use placeholders like `<your-value>`

### docs/06-deployment.md
- Docker build + run commands
- K8s deployment notes
- Environment-specific config (dev/sdx/nprd/prod)
- Link to `docs/runbooks/deploy.md`

### docs/07-operations.md
- Common operational tasks
- How to check health
- Known issues and workarounds
- Link to `docs/runbooks/incident-response.md`

### docs/08-testing.md
- How to run tests locally (`tox`, `tox -e test`)
- Test structure (unit vs integration)
- How to run a specific test
- Coverage report location (`htmlcov/index.html`)

### docs/09-development.md
- Local setup steps
- Branch naming conventions (from CONTRIBUTING.md)
- Commit format
- PR checklist reference

### docs/10-adr/
- One ADR file per architectural decision made in this service
- Use format: `001-<short-description>.md`
- Template:
  ```
  # ADR-001: [Title]
  Date: YYYY-MM
  Status: Accepted
  ## Context
  ## Decision
  ## Reasons
  ## Rejected Alternatives
  ## Consequences
  ```

### docs/11-security.md
- PHI fields in this service and how they are handled (hash/redact/never-store)
- DPDP compliance touchpoints in this service
- IRDAI audit requirements specific to this layer
- L6 integration points — where does this service call L6?
- Secrets this service uses — list names only, never values

### docs/12-integrations.md
- Every external system this service talks to
- For each: purpose, protocol (HTTP/gRPC/queue), auth method, rate limits, circuit breaker
- Connector class name and location in code
- Phase 1 vs Phase 2+ integrations clearly marked

---

## Priority order

If generating all at once, create in this order:
1. README.md, docs/00-overview.md, docs/01-architecture.md, docs/02-components.md (P0)
2. CHANGELOG.md, GLOSSARY.md, docs/03-apis.md through 05, 09, 10-adr, 11, 12 (P1)
3. docs/06-deployment.md, docs/07-operations.md (P2)
4. docs/08-testing.md (P3)
