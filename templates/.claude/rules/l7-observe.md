## L7 — Observability Rules

- Deploy L7 Day-1, never Day-2 — metrics must be live before first TPA onboards
- PHI-safe always: no raw phone, member name, or claim amounts in any metric label or log line
- tenant_id + trace_id in every log line and metric label — cross-layer correlation is mandatory
- Structured JSON logs only; every log line must have: timestamp, level, event, layer, tenant_id, trace_id, service, version; no unstructured log lines
- Metric naming convention: `gooclaim_{layer}_{metric_name}_{unit}` — e.g. `gooclaim_l1_intent_classify_duration_ms`
- Every metric must have these labels: tenant_id, layer (l0-l7), environment (dev, sdx, nprd, prod)
- Prometheus scrapes /metrics endpoints every 15 seconds; endpoint must be available on all services
- Prometheus + Grafana for metrics/dashboards (Phase 1); OpenTelemetry + Grafana Tempo for tracing (Phase 2)
- SLO tracking: 6 pilot SLOs per tenant; hard gates before TPA go-live — never skip
- Alert routing Phase 1: all alerts (P0/P1/P2) → Slack; Phase 2: P0 → PagerDuty on-call rotation, P1/P2 → Slack
- Health Aggregator: single pane of glass — service health + connector health + model health
- L7 ≠ Audit Ledger: L7 = operational monitoring (runtime health); Audit Ledger = compliance evidence (7yr IRDAI retention) — never conflate
- L7 monitors runtime health; L4 improves assets — different systems, never merge responsibilities
