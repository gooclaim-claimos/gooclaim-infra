# gooclaim-engine
> **L1 — Workflow Engine**  
> Gooclaim Claims OS · Phase 1

---

## Yeh repo kya hai

L1 Workflow Engine — Gooclaim ka decision brain.

`gooclaim-gateway` (L0) se `InteractionEvent` aata hai. L1 intent classify karta hai, sahi workflow run karta hai (RW1/RW2/RW3), aur `OutboundIntent` produce karta hai jo `gooclaim-outbound` (L5) send karta hai.

**Layer reference:** [gooclaim-infra/ARCHITECTURE.md](https://github.com/gooclaim/gooclaim-infra/blob/main/ARCHITECTURE.md)

---

## Layer Identity

| Property | Value |
|----------|-------|
| Layer | L1 |
| Internal name | Workflow Engine |
| GitHub repo | `gooclaim-engine` |
| Receives from | `gooclaim-gateway` (L0) via `InteractionEvent` |
| Calls | `gooclaim-truth` (L2), `gooclaim-knowledge` (L3) |
| Sends to | `gooclaim-outbound` (L5) via `OutboundIntent` |
| Audit events | `gooclaim-audit` via BullMQ |

---

## Phase 1 Scope

- **RW1** — Claim status (FastAPI stateless, < 3s)
- **RW2** — Pending docs (Temporal stateful, 24h cycle)
- **RW3** — Query reason (FastAPI stateless, < 3s, needs L3)
- LLM: Azure OAI via Model Gateway (classifier only)
- Output: Templates only — no free-text generation

---

## Quick Start

```bash
# Install
pip install -e ".[dev]"

# Run locally
uvicorn src.engine.main:app --reload

# Test
tox

# Single env
tox -e lint
tox -e test
```

---

## Project Structure

```
gooclaim-engine/
├── src/
│   └── engine/
│       ├── main.py              ← FastAPI app entry
│       ├── workflows/
│       │   ├── base.py          ← BaseWorkflow — extend this
│       │   ├── rw1.py           ← ClaimStatusWorkflow
│       │   ├── rw2.py           ← PendingDocsWorkflow (Temporal)
│       │   └── rw3.py           ← QueryReasonWorkflow
│       ├── classifier/
│       │   └── intent.py        ← LLM intent classifier
│       └── factory.py           ← WorkflowFactory
├── workflow_config/
│   ├── registry.yml             ← Workflow versions (IRDAI audit)
│   ├── rw1/workflow.yml
│   ├── rw2/workflow.yml
│   └── rw3/workflow.yml
├── intent_classifier/
│   ├── prompt.yml               ← LLM prompt (all workflows + languages)
│   └── intent_keywords.yml      ← Fallback keyword matching
├── tests/
│   ├── unit/
│   └── integration/
├── .github/
│   └── workflows/
│       ├── ci.yml               ← Calls gooclaim-infra CI
│       └── deploy.yml           ← Calls gooclaim-infra deploy
├── CLAUDE.md                    ← Layer-specific Claude Code rules
├── CLAUDE_SESSION.md            ← Session log (update daily)
├── tox.ini
└── pyproject.toml
```

---

## Key Rules (Claude Code + developers)

- Extend `BaseWorkflow` — never implement retry/fallback directly
- LLM classifier: `temperature=0`, `max_tokens=10` always
- RW1 + RW3: FastAPI stateless, must complete < 3s
- RW2: Temporal stateful — 24h wait cycle
- Templates only — never generate free text for users
- Every workflow execution emits audit event with version info
- Consent gate (DPDP) is Step 0 — no workflow without `CONSENT_GIVEN`
- `registry.yml` version bump mandatory on any workflow change

---

## Related Repos

| Repo | Layer | Relation |
|------|-------|----------|
| [gooclaim-gateway](https://github.com/gooclaim/gooclaim-gateway) | L0 | Sends us InteractionEvent |
| [gooclaim-truth](https://github.com/gooclaim/gooclaim-truth) | L2 | We call for claim data |
| [gooclaim-knowledge](https://github.com/gooclaim/gooclaim-knowledge) | L3 | We call for KB lookup (RW3) |
| [gooclaim-outbound](https://github.com/gooclaim/gooclaim-outbound) | L5 | Receives our OutboundIntent |
| [gooclaim-policy](https://github.com/gooclaim/gooclaim-policy) | L6 | Wraps every request |
| [gooclaim-shared](https://github.com/gooclaim/gooclaim-shared) | — | Types + contracts |
| [gooclaim-infra](https://github.com/gooclaim/gooclaim-infra) | — | CI/CD + architecture docs |
