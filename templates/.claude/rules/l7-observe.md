## L7 — Observability Rules

- Deploy L7 Day-1, never Day-2 — metrics must be live before first TPA onboards
- PHI-safe always: no raw phone, member name, or claim amounts in any metric label or log line
- tenant_id + trace_id in every log line and metric label — cross-layer correlation is mandatory
- Structured JSON logs only; every field named; no unstructured log lines
- Prometheus + Grafana for metrics/dashboards (Phase 1); OpenTelemetry + Grafana Tempo for tracing (Phase 2)
- SLO tracking: 6 pilot SLOs per tenant; hard gates before TPA go-live — never skip
- Health Aggregator: single pane of glass for service health + connector health + model health
- Alert routing: Slack for P1/P2 (fast); PagerDuty + on-call for P0 escalation
- L7 ≠ Audit Ledger: L7 = operational monitoring; Audit Ledger = compliance evidence (7yr retention) — never conflate
- L7 monitors runtime health; L4 improves assets — they are different systems, never merge responsibilities
