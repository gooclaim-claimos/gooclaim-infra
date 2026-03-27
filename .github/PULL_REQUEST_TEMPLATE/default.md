## What does this PR do?

<!-- 2-3 lines max. What changed and why. -->

## Layer / Service

<!-- e.g. L1 Workflow Engine — RW2 PendingDocsWorkflow -->

## Type of change

- [ ] feat — new feature
- [ ] fix — bug fix
- [ ] chore — dependency / config / tooling
- [ ] docs — documentation only
- [ ] test — tests only, no source change
- [ ] hotfix — urgent production fix

---

## Checklist

### Code quality
- [ ] `tox -e lint` passes locally
- [ ] `tox -e typecheck` passes locally
- [ ] `tox -e test` passes locally with coverage ≥ 80%
- [ ] No `any` types introduced
- [ ] No `print()` statements (use logger)
- [ ] No hardcoded secrets, URLs, or credentials

### Gooclaim-specific
- [ ] No PHI in logs (phone, name, claim_id as plaintext)
- [ ] Every new automated decision emits an audit event
- [ ] L6 Policy Gate not bypassed
- [ ] Consent gate (DPDP) not skipped
- [ ] If workflow changed → `registry.yml` version bumped
- [ ] If new language string added → `config/languages.yml` updated

### Tests
- [ ] Unit tests written for new business logic
- [ ] Integration test written if new connector or external call added
- [ ] Edge cases covered (NOT_FOUND, timeout, circuit breaker OPEN)

### Documentation
- [ ] `CLAUDE_SESSION.md` updated if architectural decision made
- [ ] OpenAPI spec updated if API contract changed
- [ ] ADR added to `docs/adr/` if significant architectural decision

---

## How to test this

<!-- Steps for reviewer to verify the change works -->

## Anything to watch out for?

<!-- Known risks, follow-up tasks, or things that are deferred -->
