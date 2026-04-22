# Gooclaim — Refactor Rules for Claude

When refactoring code in this repo, follow these constraints.

---

## What You Can Change

- Internal implementation details within a single layer
- Test structure and coverage improvements
- Performance optimizations that don't change behavior
- Dead code removal (verified unused via grep)
- Naming improvements within a file

## What You Must NOT Change Without Discussion

- Inter-service contracts (`InteractionEvent`, `OutboundIntent`, `AuditEvent`, `ClaimRequest`, `KBQuery`)
  → These are defined in `gooclaim-shared/src/contracts/` and affect all layers
- `config/languages.yml` — team PR review required
- `workflows/registry.yml` — version bump mandatory, team review required
- `packages/audit-ledger/` schema — requires migration + IRDAI review
- `/generated/` — auto-generated, never edit manually
- L6 Policy Gate logic — compliance-critical, must not be refactored without full architecture review (all 4 tiers: T1 exact match, T2 semantic/Guardrails AI, T3 PHI redaction, T4 source check)
- Temporal workflow logic for RW2 — durable execution semantics must be preserved; any change requires workflow version bump in `registry.yml`
- Audit event emission points — removing or changing these breaks IRDAI compliance

## Refactor Checklist

Before touching any file:
- [ ] Read the file fully — understand what it does before changing it
- [ ] Check if it's in the "Do Not Touch" list (see CLAUDE.md)
- [ ] Confirm tests exist and pass before refactoring
- [ ] Confirm tests still pass after refactoring
- [ ] No behavior change — refactor = same output, better code

## Layer Boundaries — Never Cross

```
L1 decides  →  L5 executes       (never mix)
L2 fetches  →  L1 uses           (L1 never calls external APIs directly)
L3 knows    →  L1 uses, L6 gates (L3 never decides what to show)
L6 gates    →  everything        (never remove L6 from any output path)
```

## When Refactoring Connectors (L2, L3, L5)

- Keep the `ICMSConnector`, `IDocConnector` ABCs intact — concrete implementations can change
- Rate limiting, health monitoring, retry logic, circuit breakers must remain
- Audit logging in connectors must remain — these are compliance points
- Do not change connector interface signatures without updating all consumers

## Imports

- Never add direct Azure OpenAI SDK import — always `ModelGatewayClient`
- Never import secrets directly — always via ESO wrapper
- Shared types must come from `gooclaim-shared` — do not duplicate
