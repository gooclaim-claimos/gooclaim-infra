# ADR-005: L2 Truth Layer Read-Only in Phase 1

**Date:** March 2026
**Status:** Accepted
**Deciders:** Team

---

## Context

L2 Truth Layer connects to TPA CMS (MediAssist and others) to fetch claim data. Should L2 also write back to CMS in Phase 1 (e.g., update claim status, mark docs received)?

## Decision

**L2 is read-only in Phase 1 and Phase 2.** No write-back to CMS until Phase 3.

## Reasons

- De-risk the pilot — connector bugs in read mode cannot corrupt claim data
- TPA confidence: TPAs are more comfortable with a read-only integration initially
- Write-back requires significantly more testing and TPA-side integration work
- Phase 1 containment goal (>60% auto-resolution) is achievable without write-back
- Human escalation path handles cases that would require write-back

## Write-Back Unlock Criteria (Phase 2)

Write-back enables in Phase 2 after:
- L2 read connector proven stable for 3+ months
- TPA explicitly approves write-back integration
- Write-back operations gated by human approval in Internal Console
- Full audit trail for every write-back operation

## Consequences

- `ICMSConnector` interface has `fetch_*` methods only — no `update_*` in Phase 1
- Cases requiring CMS updates → human ticket created → human agent handles
- L2 connector chain: API → CSV/SFTP Feed → RPA fallback (all read operations)
- Rate limit known: CMS API 10 req/min — throttle + queue in L2 connector (see Known Issue I-001)
