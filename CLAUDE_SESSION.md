# CLAUDE_SESSION.md — Gooclaim Session Memory
> Updated at START and END of every Claude Code session.
> Committed to git after each session (or at end of day).
> This is the handoff document — next engineer picks up from here.

---

## Current State

```
Sprint:        Sprint [X] — [Sprint Name]
Week:          Week [X] of 16
Phase:         Phase 1 — Pilot
Active layer:  [e.g. L1-workflow-engine]
Build status:  [GREEN / YELLOW / RED]
Blocking:      [None / describe blocker]
```

---

## Session Log

<!-- Most recent session on top -->

### [DATE] — [Engineer Name] — Session [N]

**Started:** [HH:MM IST]
**Ended:** [HH:MM IST]
**Layer / Service:** [e.g. L1 Workflow Engine]
**Branch:** [feature/rw1-claim-status]

**Goal for this session:**
[What did you set out to do?]

**What was done:**
- [Concrete task 1]
- [Concrete task 2]
- [Concrete task 3]

**Decisions made:**
- [Decision + reason — these are the most important things to log]
- [e.g. "Used Temporal for RW2 because FastAPI can't handle 24h wait — see L1 doc §7"]

**Files changed:**
- `apps/l1-workflow-engine/src/workflows/rw1.ts` — [what changed]
- `config/workflow_config/registry.yml` — [what changed]

**Tests:**
- [ ] Unit tests: [pass / fail / not written yet]
- [ ] Integration tests: [pass / fail / skipped]
- [ ] Coverage: [X%]

**What's next (for next session or next engineer):**
- [ ] [Task 1]
- [ ] [Task 2]

**Open questions / blockers:**
- [Question or blocker — tag person if known @name]

**Claude Code notes (auto-patterns Claude learned this session):**
- [e.g. "ModelGatewayClient timeout should be 8s not 5s for embedding calls"]
- [e.g. "RPA fallback in L2 hits rate limit above 10 req/min — need throttle"]

---

<!-- Copy the block above for each new session -->

---

## Architectural Decisions Log (ADL)

> Permanent record. Never delete entries. Add new ones on top.

| Date | Decision | Reason | Who |
|------|----------|--------|-----|
| 2026-03 | L6 T2: Guardrails AI (not NeMo) | Hinglish non-deterministic, not IRDAI auditable in Phase 1 | Team |
| 2026-03 | L2: Read-only Phase 1 | De-risk pilot — no write-back until connectors proven | Team |
| 2026-03 | L1 RW2: Temporal (not FastAPI) | 24h wait cycle — FastAPI stateless can't handle | Team |
| 2026-03 | Templates only Phase 1 | Zero hallucination requirement, IRDAI compliance | Team |
| 2026-03 | Language: HI_EN default | Professional operators — Hinglish most common | Team |

---

## Known Issues & Workarounds

> Running list. Mark resolved ones with ~~strikethrough~~.

| ID | Layer | Issue | Workaround | Status |
|----|-------|-------|------------|--------|
| I-001 | L2 | CMS API rate limit 10 req/min | Throttle + queue in L2 connector | Open |
| I-002 | L6 | Guardrails AI cold start ~2s | Warm pool in Docker | Open |

---

## Environment Status

| Env | Status | Last deploy | Notes |
|-----|--------|-------------|-------|
| dev | [UP/DOWN] | [date] | local + CI |
| sdx (sandbox) | [UP/DOWN] | [date] | shared team env |
| nprd (non-prod) | [UP/DOWN] | [date] | pre-pilot testing |
| prod | NOT YET | — | Phase 1 pilot target |

---

## Module Checklist — Phase 1

> Updated as components reach "done" (tests passing, integrated, deployed to sdx).

| Component | Status | Engineer | Notes |
|-----------|--------|----------|-------|
| Secrets Vault | ⬜ Not started | — | |
| Platform Infra | ⬜ Not started | — | K8s + Redis + PG + BullMQ |
| Access Control | ⬜ Not started | — | RBAC schema + JWT |
| Model Gateway | ⬜ Not started | — | Azure OAI + routing |
| L3 Knowledge Layer | ⬜ Not started | — | Haystack + pgvector |
| L6 Policy Gate | ⬜ Not started | — | T1 + Guardrails AI + PHI |
| L2 Truth Layer | ⬜ Not started | — | ICMSConnector + CB |
| Connector Hub | ⬜ Not started | — | WhatsApp WABA |
| L0 Channel Gateway | ⬜ Not started | — | Webhook + lang detect |
| L1 — RW1 | ⬜ Not started | — | Claim status |
| L1 — RW2 | ⬜ Not started | — | Pending docs + Temporal |
| L1 — RW3 | ⬜ Not started | — | Query reason + L3 |
| L5 Outbound Engine | ⬜ Not started | — | Templates + retry |
| Audit Ledger | ⬜ Not started | — | BullMQ + 7yr retention |
| L4 Learning Loop | ⬜ Not started | — | Passive mode only |
| L7 Observability | ⬜ Not started | — | Metrics + alerting |
| Internal Console (min) | ⬜ Not started | — | Tickets + KB + Audit |
| Security Hardening | ⬜ Not started | — | TruffleHog + mTLS |

Status values: ⬜ Not started · 🟡 In progress · ✅ Done (sdx) · 🚀 Deployed (nprd)

---

## Claude Code Patterns Learned (Team-Wide)

> When Claude Code figures out something non-obvious about our codebase — log it here.
> This supplements Auto Memory for team-shared learnings.

- [2026-03] ModelGatewayClient: always pass `tenant_id` in request context — omitting it causes fallback to default model with no audit trail
- [2026-03] BullMQ workers: set `concurrency: 1` for REGULATORY tier audit events — order must be guaranteed
- [Add new patterns here as discovered]

---

## Session Start Checklist (run every time you open Claude Code)

```
[ ] Pull latest main / your branch
[ ] Read the last session entry in this file
[ ] Check "What's next" from last session
[ ] Check "Open questions / blockers"
[ ] Check Module Checklist for your layer's status
[ ] Set your session goal — write it in new session block before starting
```

## Session End Checklist (run before closing Claude Code)

```
[ ] Fill in "What was done" in session block
[ ] Log any new architectural decisions in ADL
[ ] Update Module Checklist statuses
[ ] Log any new Known Issues
[ ] Fill in "What's next"
[ ] Log any Claude Code patterns learned
[ ] Commit this file: git add CLAUDE_SESSION.md && git commit -m "docs: session log [DATE] [NAME]"
[ ] Push branch
```
