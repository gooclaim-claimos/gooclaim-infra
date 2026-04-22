# ADR-001: Temporal for RW2 (Pending Docs Workflow)

**Date:** March 2026
**Status:** Accepted
**Deciders:** Team

---

## Context

RW2 (Pending Docs workflow) requires waiting up to 24 hours for a hospital/user to upload documents. The system must:
- Send an upload link via WhatsApp
- Wait for document upload (up to 24h)
- Resume workflow on upload event
- Escalate to human ticket on timeout

## Decision

Use **Temporal** for RW2 instead of FastAPI.

## Reasons

- FastAPI is stateless — cannot maintain a 24h wait cycle without external state management
- Temporal provides durable execution — if service restarts, workflow resumes exactly where it left
- Temporal handles retries, timeouts, and signals natively
- RW1 and RW3 remain FastAPI (stateless, < 3s) — only RW2 needs Temporal
- Temporal already in stack for future agentic workflows (Phase 3)

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| FastAPI + Redis TTL polling | State loss on restart, polling is wasteful, complex retry logic |
| Celery | No durable execution, harder to debug long-running workflows |
| BullMQ delayed jobs | No built-in signal/resume — complex to implement doc-upload event handling |

## Consequences

- Temporal worker must be running as a separate process (`pnpm temporal:worker`)
- RW2 workflow must be versioned in `registry.yml`
- Local dev: `docker compose up` includes Temporal server
