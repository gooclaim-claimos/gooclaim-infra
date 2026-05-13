# gooclaim-service — Golden Helm chart

> The reference Helm chart that every Gooclaim platform service inherits from.

## Why a golden chart?

The Gooclaim platform has 16 microservices. Without a shared chart pattern, each repo would author its own Deployment / Service / Ingress / ExternalSecret / ConfigMap / ServiceMonitor — and the configuration would drift across services. With this golden chart:

- A new service deploys with a 30-line `values.yaml` override
- Security defaults (non-root, read-only rootfs, dropped caps) apply everywhere
- TLS, secret-rotation, Prometheus scrape all wired identically
- One PR to this template propagates to every service after the next release

## Rendered resources

| Resource | Created when |
|---|---|
| `Deployment` | always |
| `Service` (ClusterIP) | always |
| `ServiceAccount` | `serviceAccount.create=true` (default) |
| `Ingress` | `ingress.enabled=true` AND `ingress.host` non-empty |
| `ExternalSecret` | `secretsFromAkv.enabled=true` |
| `ConfigMap` | `configMap.enabled=true` |
| `ServiceMonitor` | `prometheus.enabled=true` |
| `PodDisruptionBudget` | `podDisruptionBudget.enabled=true` AND `replicaCount > 1` |
| `HorizontalPodAutoscaler` | `autoscaling.enabled=true` |

## How a service repo consumes this

The chart is **copied** into the service repo, not referenced as a dependency, so each service can override templates if needed. The typical flow:

```bash
# In the new service repo (e.g. gooclaim-auth)
mkdir -p helm
cp -r ../gooclaim-infra/templates/helm/gooclaim-service helm/gooclaim-auth
cd helm/gooclaim-auth

# Edit Chart.yaml — change name to `gooclaim-auth`
# Edit values.yaml — set image, port, ingress.host, secretsFromAkv, configMap

# Install
helm install gooclaim-auth ./helm/gooclaim-auth \
  --namespace gooclaim --create-namespace
```

## Example: gooclaim-auth values.yaml override

```yaml
name: gooclaim-auth

image:
  repository: gooclaimacrdev.azurecr.io/gooclaim-auth
  tag: v0.1.0

serviceAccount:
  workloadIdentityClientId: "<UAMI client_id with AcrPull + KV Secrets User>"

ports:
  - name: http
    containerPort: 8000

service:
  port: 80
  targetPort: http

ingress:
  enabled: true
  host: auth.dev.gooclaim.com
  clusterIssuer: letsencrypt-prod

secretsFromAkv:
  enabled: true
  data:
    - secretKey: JWT_PRIVATE_KEY
      remoteRef: gooclaim-auth-jwt-private-key
    - secretKey: JWT_PUBLIC_KEY
      remoteRef: gooclaim-auth-jwt-public-key
    - secretKey: POSTGRES_PASSWORD
      remoteRef: gooclaim-postgres-admin-password

configMap:
  enabled: true
  data:
    LOG_LEVEL: INFO
    POSTGRES_HOST: gooclaim-pg-dev.postgres.database.azure.com
    POSTGRES_DB: gooclaim_auth
    POSTGRES_USER: gooclaimadmin
    SERVICE_NAME: gooclaim-auth
    DEPLOY_ENV: dev

prometheus:
  enabled: true
  path: /metrics

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Service contract — what your app must implement

For the chart's defaults to work, the service app needs:

| Contract | Default expectation |
|---|---|
| Liveness probe | `GET /healthz` returns 200 OK when process is alive |
| Readiness probe | `GET /readyz` returns 200 OK when deps (DB / KV / Redis) reachable |
| Metrics endpoint | `GET /metrics` Prometheus exposition format (if prometheus.enabled) |
| HTTP port | 8000 by default (override via `ports[].containerPort`) |
| Non-root user | Process runs as UID 1000 (image must support this) |
| Read-only rootfs | App writes only to `/tmp` (or mounted emptyDir) |
| Graceful shutdown | App handles SIGTERM cleanly within 30s (TerminationGracePeriodSeconds) |

## Versioning

- **Chart version** (`Chart.yaml` `version`): bump when template logic changes
- **App version** (`Chart.yaml` `appVersion`): default tag if `image.tag` not set
- **Image tag** (`values.yaml` `image.tag`): per-deploy, overrides appVersion

When the template changes:

1. Bump `Chart.yaml.version` in this folder (gooclaim-infra)
2. Open PR
3. After merge, each service repo can `cp -r` the new template into their `helm/` and bump its chart version
4. Roll services on schedule

## v1.0+ enhancements (deferred)

- **NetworkPolicy** — egress allowlist per service (compliance hardening)
- **Pod-level rate limit** annotation
- **Dual-tenancy labels** (multi-cluster federation)
- **Inheritable common-overrides values.yaml** at gooclaim-infra level

---

**Maintainer:** Gooclaim Platform Team
**Last updated:** 2026-05-13 (Day 6)
