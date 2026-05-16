# Postman / Newman collections

Per-service Postman collections used for manual exploration in the
Postman UI + scripted smoke gates via Newman in CI.

## Foundation Day 2 — S2 smoke gate

`foundation-day2.postman_collection.json` exercises the 8 cross-app
endpoints landed in S2 across 4 services (auth, audit, engine,
connector-hub). The first request mints a JWT via `/v1/auth/login` and
every subsequent request consumes it.

### Run against dev cluster

```bash
# from gooclaim-infra root
npx newman run postman/foundation-day2.postman_collection.json \
    -e postman/foundation-day2.postman_environment.json
```

### Run against any environment

Override `base_url_*` per service:

```bash
npx newman run postman/foundation-day2.postman_collection.json \
    --env-var base_url_auth=https://api.nprd.gooclaim.com \
    --env-var base_url_audit=https://api.nprd.gooclaim.com \
    --env-var base_url_engine=https://api.nprd.gooclaim.com \
    --env-var base_url_hub=https://api.nprd.gooclaim.com \
    --env-var test_email=... --env-var test_password=...
```

### What the gate asserts

Each of the 9 requests has Postman tests checking:

| # | Endpoint | Asserts |
|---|---|---|
| 0 | POST /v1/auth/login | 200, access_token returned (stashed for subsequent requests) |
| 1 | GET /v1/auth/me | 200, user_id + tenant_id + roles + mfa_verified shape |
| 2 | GET /v1/notifications | 200, items array + total + unread numbers |
| 3 | POST /v1/notifications/read-all | 200, marked is a number ≥ 0 |
| 4 | GET /v1/service-accounts | 200, items array + total, **secret never leaked** |
| 5 | POST /v1/admin/break-glass/request | 200 or 403 (role-gated; either proves the route is alive) |
| 6 | GET /v1/audit/events | 200, items array + total + next_cursor is null-or-string |
| 7 | GET /v1/consent/status | 200 or 400 (tenant validation), consent_given boolean |
| 8 | GET /v1/integrations | 200, items array, type ∈ {cms, doc}, CB state ∈ {CLOSED, OPEN, HALF_OPEN} |

### When to run it

- **Post-deploy smoke**: after a fresh image bake + dev cluster rollout,
  run the gate to confirm all 8 endpoints came up alive.
- **Pre-merge guard** (S2 Beta gate): wire as a CI step before
  promoting an image from dev → nprd.

### Not a contract test

Full schema validation lives in each service's pytest suite. This
collection is a shallow smoke gate — proves the endpoints are wired,
auth flows work, and the response shape is recognisable. It doesn't
exhaustively cover edge cases.

### Per-service collections

Each service also ships its own collection (`gooclaim-auth.postman_collection.json`,
etc.) for deeper manual exploration. Foundation Day 2 cuts across
services so it lives at this combined-collection layer.
