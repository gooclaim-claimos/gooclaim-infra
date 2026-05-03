# Gooclaim Platform Versions

> **Single source of truth** for platform-wide release state.
> Each repo carries its own SemVer; this manifest locks the snapshot per platform release.

**Last updated:** May 2026

---

## Current state — Pre-v1.0 (May 2026)

Building toward **v1.0 pilot launch**. Each repo at its own pre-pilot version reflecting shipped maturity.

### Backend services (16)

| Repo | Version | Status | Description |
|------|---------|--------|-------------|
| [`gooclaim-shared`](https://github.com/gooclaim-claimos/gooclaim-shared) | **v0.22.0** | mature | Shared library — contracts, enums, middleware, registry-first source of truth |
| [`gooclaim-auth`](https://github.com/gooclaim-claimos/gooclaim-auth) | **v0.5.0** | code-complete | Auth backbone — RS256 JWT, RBAC, MFA, DPDP consent records |
| [`gooclaim-audit`](https://github.com/gooclaim-claimos/gooclaim-audit) | **v0.5.0** | code-complete | Audit ledger — IRDAI 7yr retention, BullMQ, partitioned Postgres |
| [`gooclaim-gateway`](https://github.com/gooclaim-claimos/gooclaim-gateway) | **v0.5.0** | code-complete | Channel Gateway — WhatsApp inbound, 3-Gate design (92% cov) |
| [`gooclaim-whatsapp`](https://github.com/gooclaim-claimos/gooclaim-whatsapp) | **v0.5.0** | code-complete | WhatsApp WABA channel adapter — webhook signing, HSM templates |
| [`gooclaim-engine`](https://github.com/gooclaim-claimos/gooclaim-engine) | **v0.5.0** | code-complete | Workflow Engine — Temporal-backed pending-docs, claim-status, query-reason |
| [`gooclaim-connector-hub`](https://github.com/gooclaim-claimos/gooclaim-connector-hub) | **v0.5.0** | code-complete | Connector Hub — circuit breaker per-tenant, fallback chain |
| [`gooclaim-truth`](https://github.com/gooclaim-claimos/gooclaim-truth) | **v0.5.0** | code-complete | Truth Layer — read-only CMS connectors (97% cov) |
| [`gooclaim-knowledge`](https://github.com/gooclaim-claimos/gooclaim-knowledge) | **v0.5.0** | code-complete | Knowledge Layer — Haystack + pgvector (92% cov) |
| [`gooclaim-policy`](https://github.com/gooclaim-claimos/gooclaim-policy) | **v0.5.0** | code-complete | Policy Gate — T1-T4 tiers (exact match, semantic safety, PHI redaction, source grounding) |
| [`gooclaim-outbound`](https://github.com/gooclaim-claimos/gooclaim-outbound) | **v0.5.0** | code-complete | Outbound Engine — template-only sends, multi-channel ready |
| [`gooclaim-model-gateway`](https://github.com/gooclaim-claimos/gooclaim-model-gateway) | **v0.5.0** | code-complete | Model Gateway — Azure OpenAI proxy, per-tenant rate limits |
| [`gooclaim-template-registry`](https://github.com/gooclaim-claimos/gooclaim-template-registry) | **v0.5.0** | code-complete | Template Registry — DRAFT→PENDING→APPROVED state machine |
| [`gooclaim-tenant-config`](https://github.com/gooclaim-claimos/gooclaim-tenant-config) | **v0.5.0** | code-complete | Tenant Config — per-tenant op_mode + workflow enablement (100% cov) |
| [`gooclaim-observe`](https://github.com/gooclaim-claimos/gooclaim-observe) | **v0.3.1** | recent release | Observability — Prometheus + Grafana + Loki + Health Aggregator |
| [`gooclaim-load-tests`](https://github.com/gooclaim-claimos/gooclaim-load-tests) | **v0.1.0** | scaffolding | Cross-platform load + stress test scenarios (k6 / Locust) |

### Frontend apps (5)

| Repo | Version | Status | Description |
|------|---------|--------|-------------|
| [`gooclaim-console`](https://github.com/gooclaim-claimos/gooclaim-console) | **v0.2.0** | UI scaffold + HTTPS setup | Internal Operations Console (admin) |
| [`gooclaim-portal`](https://github.com/gooclaim-claimos/gooclaim-portal) | **v0.2.0** | UI scaffold | TPA Admin Portal (KB management) |
| [`gooclaim-copilot`](https://github.com/gooclaim-claimos/gooclaim-copilot) | **v0.2.0** | UI scaffold + HTTPS setup | TPA Agent Copilot (claims workspace) |
| [`gooclaim-landing-page`](https://github.com/gooclaim-claimos/gooclaim-landing-page) | **v0.3.0** | most polished | Public marketing site |
| [`gooclaim-workflow-studio`](https://github.com/gooclaim-claimos/gooclaim-workflow-studio) | **v0.1.0** | initial release | Visual workflow builder (drag-drop canvas) |

### Documentation (1)

| Repo | Version | Status | Description |
|------|---------|--------|-------------|
| [`gooclaim-docs`](https://github.com/gooclaim-claimos/gooclaim-docs) | **v0.5.0** | foundation in place | Platform-wide documentation (audience-first migration pending) |

---

## v1.0 — Pilot launch (target: ~3-5 weeks out)

**v1.0 = first production release for real TPAs** — coordinated bump across all repos.

When v1.0 ships, ALL repos coordinate-bump to v1.0.0 simultaneously, regardless of their pre-pilot path. The platform release tags this snapshot.

| Repo | Pre-v1.0 | v1.0.0 target |
|------|----------|---------------|
| gooclaim-shared | v0.22.0 | **v1.0.0** |
| gooclaim-auth | v0.5.0 | **v1.0.0** |
| gooclaim-audit | v0.5.0 | **v1.0.0** |
| gooclaim-gateway | v0.5.0 | **v1.0.0** |
| gooclaim-whatsapp | v0.5.0 | **v1.0.0** |
| gooclaim-engine | v0.5.0 | **v1.0.0** |
| gooclaim-connector-hub | v0.5.0 | **v1.0.0** |
| gooclaim-truth | v0.5.0 | **v1.0.0** |
| gooclaim-knowledge | v0.5.0 | **v1.0.0** |
| gooclaim-policy | v0.5.0 | **v1.0.0** |
| gooclaim-outbound | v0.5.0 | **v1.0.0** |
| gooclaim-model-gateway | v0.5.0 | **v1.0.0** |
| gooclaim-template-registry | v0.5.0 | **v1.0.0** |
| gooclaim-tenant-config | v0.5.0 | **v1.0.0** |
| gooclaim-observe | v0.3.1 | **v1.0.0** |
| gooclaim-load-tests | v0.1.0 | **v1.0.0** |
| gooclaim-console | v0.2.0 | **v1.0.0** |
| gooclaim-portal | v0.2.0 | **v1.0.0** |
| gooclaim-copilot | v0.2.0 | **v1.0.0** |
| gooclaim-landing-page | v0.3.0 | **v1.0.0** |
| gooclaim-workflow-studio | v0.1.0 | (parallel — workflow studio versioned independently) |
| gooclaim-docs | v0.5.0 | **v1.0.0** |

### v1.0 includes

- Channel Gateway (WhatsApp inbound only)
- Workflow Engine (claim-status, pending-docs, query-reason workflows + DPDP consent capture)
- Truth Layer (read-only CMS connectors)
- Knowledge Layer (semantic + keyword KB search)
- Outbound Engine (WhatsApp template sends only)
- Policy Gate (T1-T4 compliance gates)
- Observability (Prometheus + Grafana + Loki + Alertmanager + Health Aggregator)
- Audit Ledger (IRDAI 7yr retention)
- Auth backbone (RS256 JWT, RBAC, MFA TOTP)
- Internal Operations Console + TPA Admin Portal + TPA Agent Copilot + Public Landing
- 5 SLOs (containment, latency, connector errors, audit completeness, channel availability)

### v1.0 does NOT include

- Learning Loop active mode (passive signal capture only)
- Voice channel
- SMS / Email channels
- Workflow Studio drag-drop builder (parallel work in v0.x)
- Write-back to CMS (Truth Layer is read-only in v1.0)
- gooclaim-scout (auto KB updates from regulator content)
- Per-tenant SLOs

---

## v1.1 — Post-launch polish (target: ~3 months post-v1.0)

Bug fixes, polish, minor features after pilot soak.

- All P1 alerts get runbooks (12 more SOPs)
- Error budget burn-rate alerts
- Workflow Studio internal-team release (Gooclaim ops only)
- Console premium redesign (Linear-tier polish)
- Backend wiring for all frontends complete
- TPA self-service onboarding flow

---

## v2.0 — Major capability expansion (target: ~12-18 months post-v1.0)

- Learning Loop active mode (per-tenant claims-domain brain)
- Voice channel (gooclaim-voice — separate service)
- SMS + Email channels (multi-channel orchestration)
- Workflow Studio TPA self-service mode
- Write-back to CMS (Truth Layer expansion)
- gooclaim-scout (auto KB updates via Tavily/Serper/Exa/Firecrawl)
- Per-tenant SLOs
- PagerDuty integration
- Distributed tracing (OpenTelemetry + Grafana Tempo)

---

## v3.0 — Advanced agentic + scale (target: ~24-36 months post-v1.0)

- ML anomaly detection (auto-detect SLO violations before threshold)
- Multi-region failover (Singapore DR backup)
- Autonomous agentic loops (self-healing workflows)
- Datadog / advanced log analytics (optional migration)
- Active learning models (real LLM fine-tuning)

---

## SemVer rules — when each repo bumps

```
MAJOR (X.0.0)  →  Breaking change. Customers/integrations will need updates.
MINOR (0.X.0)  →  New feature, backwards-compatible.
PATCH (0.0.X)  →  Bug fix only.
```

Each repo carries its own version. Platform releases (v1.0, v1.1, v2.0) are coordinated snapshots locked in this file.

## How to bump a repo

```bash
# 1. Edit pyproject.toml or package.json — bump version
# 2. Add CHANGELOG.md entry (top of file)
# 3. Commit + PR to develop → merge → cherry to main
# 4. Tag main: git tag -a vX.Y.Z -m "..."
# 5. Push tag: git push origin vX.Y.Z
# 6. Create GitHub Release with tag
# 7. (For platform-wide bumps) update this VERSIONS.md
```

## How to release a new platform version (v1.0 → v1.1 etc.)

```
1. Confirm all participating repos are at their target versions
2. Update this VERSIONS.md with the new platform version section
3. Commit VERSIONS.md change to monorepo root
4. Optional: tag monorepo root with platform version (v1.0, v1.1)
5. Announce in #gooclaim-releases Slack
6. Update marketing material if customer-facing change
```

---

## See also

- [`CONTRIBUTING.md`](CONTRIBUTING.md) — branch naming, commit format, PR process
- [`CLAUDE.md`](CLAUDE.md) — project memory + hard rules
- Each repo's `CHANGELOG.md` — repo-specific history
- Each repo's GitHub Releases page — version artifacts + binaries
