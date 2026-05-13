# Cloud bootstrap — Gooclaim Azure deploy from zero

> End-to-end runbook for recreating the Gooclaim dev cluster on Azure.
> Same pattern applies to nprd and prod (change `var.environment` + resource SKUs).
>
> Total wall-clock: 2-3 hours for a fresh build. Most steps are idempotent.

---

## What you'll provision

```
Resource Group: gooclaim-rg-<env>  (centralindia, DPDP §16 locked)
├── Azure Container Registry      (gooclaimacr<env>)
├── AKS cluster + Log Analytics   (2 nodes Standard_D2s_v3 for dev)
├── Key Vault                     (RBAC auth, 90d soft-delete)
├── Postgres 16 Flexible Server   (B1ms for dev)
├── Azure Cache for Redis         (Basic C0 for dev)
├── Storage Account               (4 containers)
└── User-Assigned Managed Identity (for ESO + per-service WI later)

Cluster Helm releases (5):
├── external-secrets              (AKV → K8s secrets bridge)
├── cert-manager                  (Let's Encrypt TLS auto-issue)
├── ingress-nginx                 (public LB + HTTPS)
├── kube-prometheus-stack         (Prometheus + Alertmanager + Grafana)
├── loki + promtail               (log aggregation)
└── temporal                      (workflow engine for L1)
```

---

## Prerequisites (one-time)

```bash
# Tools
brew install azure-cli terraform kubernetes-cli helm

# Azure auth
az login   # opens browser; use admin@gooclaim.com (or env-specific account)
az account set --subscription "<subscription-id>"

# Register Azure resource providers (one-off per subscription)
for ns in Microsoft.Storage Microsoft.ContainerService Microsoft.Network \
          Microsoft.KeyVault Microsoft.DBforPostgreSQL Microsoft.Cache \
          Microsoft.OperationalInsights Microsoft.ManagedIdentity Microsoft.Compute \
          Microsoft.ContainerRegistry; do
  az provider register --namespace $ns --wait
done
```

---

## Phase 1 — Foundation (Day 1)

### Step 1: AAD groups + RBAC

```bash
# Create 3 groups
for g in gooclaim-admins gooclaim-devs gooclaim-readers; do
  az ad group create --display-name "$g" --mail-nickname "$g"
done

# Add yourself to admins
USER_ID=$(az ad signed-in-user show --query id -o tsv)
az ad group member add --group gooclaim-admins --member-id "$USER_ID"

# Owner role on subscription
SUB_ID=$(az account show --query id -o tsv)
ADMINS_ID=$(az ad group show --group gooclaim-admins --query id -o tsv)
az role assignment create --assignee "$ADMINS_ID" --role Owner --scope "/subscriptions/$SUB_ID"
```

### Step 2: Budget alerts

Open `https://portal.azure.com` → Cost Management → Budgets. Create 3 monthly budgets at ₹5K / ₹10K / ₹30K thresholds with 80% alert to `admin@gooclaim.com`.

### Step 3: Resource Group + Terraform state backend

```bash
# RG
az group create --name gooclaim-rg-dev --location centralindia \
  --tags env=dev owner=gooclaim cost-center=pilot

# Storage Account for tfstate (must be globally unique)
az storage account create \
  --name gooclaimtfstatedev \
  --resource-group gooclaim-rg-dev \
  --location centralindia \
  --sku Standard_LRS --kind StorageV2 \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

# Versioning + soft-delete (recovery from accidental tfstate corruption)
az storage account blob-service-properties update \
  --account-name gooclaimtfstatedev \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 90

# Blob container
az storage container create \
  --name tfstate --account-name gooclaimtfstatedev --auth-mode login

# Grant yourself Storage Blob Data Owner on the account (data-plane access for tf init)
ACCOUNT_ID=$(az storage account show --name gooclaimtfstatedev \
  --resource-group gooclaim-rg-dev --query id -o tsv)
az role assignment create --assignee "$USER_ID" \
  --role "Storage Blob Data Owner" --scope "$ACCOUNT_ID"
```

### Step 4: Terraform apply (foundation + data + ACR)

```bash
cd terraform/environments/dev

# First-time: pick up backend + providers
terraform init

# Customize tfvars
cp terraform.tfvars.example terraform.tfvars
# (edit if you need overrides)

terraform plan -out=foundation.tfplan
terraform apply foundation.tfplan
```

This provisions: AKS + KV + Postgres + Redis + Storage + Workload Identity + ACR (with `azure.extensions` allow-list for Temporal-needed `btree_gin` + L3 `vector`).

Wall-clock: ~18 min (Redis Basic C0 is the slowest gate).

### Step 5: Get cluster credentials

```bash
az aks get-credentials --resource-group gooclaim-rg-dev --name gooclaim-aks-dev
kubectl get nodes   # expect 2 Ready
```

---

## Phase 2 — Secrets pipeline (Day 3)

Terraform writes the 3 sensitive values from earlier modules into AKV:

```bash
# Already wired in terraform/environments/dev/main.tf
# After previous apply, verify:
az keyvault secret list --vault-name gooclaim-kv-dev --query "[].name" -o tsv
# Should show: gooclaim-postgres-admin-password
#              gooclaim-redis-primary-key
#              gooclaim-storage-primary-key
```

Then install External Secrets Operator with Workload Identity binding:

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

CLIENT_ID=$(cd terraform/environments/dev && terraform output -raw wi_eso_client_id)

helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --version 2.4.1 \
  -f helm/external-secrets/values-dev.yaml \
  --set-string "serviceAccount.annotations.azure\.workload\.identity/client-id=${CLIENT_ID}"
```

Wire the ClusterSecretStore:

```bash
export AZURE_TENANT_ID=$(cd terraform/environments/dev && terraform output -raw tenant_id)
envsubst < helm/external-secrets/cluster-secret-store.yaml | kubectl apply -f -

kubectl get clustersecretstore gooclaim-azurekv-dev   # Ready=True within 5s
```

---

## Phase 3 — Ingress + TLS (Day 4)

```bash
# cert-manager
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version v1.20.2 \
  -f helm/cert-manager/values-dev.yaml

# Wait for pods, then apply ClusterIssuers
kubectl apply -f helm/cert-manager/cluster-issuers.yaml

# NGINX Ingress (provisions Azure Standard LB → public IP)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --version 4.15.1 \
  -f helm/ingress-nginx/values-dev.yaml

# Capture public IP
kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Manual step (one-time per env):** add DNS A records at the gooclaim.com DNS provider:

| Host | Type | Value | Proxy |
|---|---|---|---|
| `api-dev.gooclaim.com` | A | `<LB IP>` | DNS only (grey cloud at Cloudflare) |
| `*.dev.gooclaim.com` | A | `<LB IP>` | DNS only |

For nprd: `api-nprd.gooclaim.com` + `*.nprd.gooclaim.com`.
For prod: `*.gooclaim.com` apex.

Critical: **DNS only (grey cloud)** at Cloudflare — HTTP-01 ACME challenge needs direct hit to LB, Cloudflare proxy would intercept it.

---

## Phase 4 — Observability + workflow engine (Day 5)

```bash
# Prometheus stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
GRAFANA_PASS=$(openssl rand -base64 24 | tr -d '/=+' | cut -c -20)
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --version 85.0.2 \
  -f helm/kube-prometheus-stack/values-dev.yaml \
  --set-string "grafana.adminPassword=${GRAFANA_PASS}"

# Save Grafana password to AKV
az keyvault secret set --vault-name gooclaim-kv-dev \
  --name gooclaim-grafana-admin-password \
  --value "$GRAFANA_PASS"
unset GRAFANA_PASS

# Expose Grafana
kubectl apply -f helm/kube-prometheus-stack/ingress-grafana.yaml

# Loki + Promtail
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki \
  --namespace monitoring \
  --version 7.0.0 -f helm/loki/values-dev.yaml

helm install promtail grafana/promtail \
  --namespace monitoring \
  --version 6.17.1 -f helm/promtail/values-dev.yaml

# Postgres extensions allow-list (Temporal needs btree_gin) — already in
# terraform/modules/postgres. Verify:
az postgres flexible-server parameter show \
  -g gooclaim-rg-dev -s gooclaim-pg-dev -n azure.extensions \
  --query value -o tsv

# Pre-create Temporal databases (chart's createDatabase=false)
# Use a one-shot pod (see helm/temporal docs for the manifest)

# Temporal
helm repo add temporal https://temporalio.github.io/helm-charts
kubectl create namespace temporal
kubectl apply -f helm/temporal/temporal-pg-secret.yaml   # ExternalSecret pulls PG password

helm install temporal temporal/temporal \
  --namespace temporal \
  --version 1.2.0 -f helm/temporal/values-dev.yaml

# Register the 'default' Temporal namespace (or rely on values.yaml's
# namespaces.create=true for future installs)
kubectl exec -n temporal deploy/temporal-admintools -- \
  temporal --address temporal-frontend:7233 operator namespace create default \
  --retention 168h
```

---

## Phase 5 — Service deploys (Week 2+)

Each service (16 total) uses the golden Helm chart at `templates/helm/gooclaim-service/`:

```bash
# In a service repo (e.g. gooclaim-auth)
mkdir -p helm
cp -r ../gooclaim-infra/templates/helm/gooclaim-service helm/gooclaim-auth

# Edit helm/gooclaim-auth/Chart.yaml — change name + appVersion
# Edit helm/gooclaim-auth/values.yaml — set image, ingress.host, secretsFromAkv, configMap

# Build + push image
az acr login --name gooclaimacrdev
docker build -t gooclaimacrdev.azurecr.io/gooclaim-auth:v0.1.0 .
docker push gooclaimacrdev.azurecr.io/gooclaim-auth:v0.1.0

# Deploy
helm install gooclaim-auth ./helm/gooclaim-auth \
  --namespace gooclaim --create-namespace
```

See `templates/helm/gooclaim-service/README.md` for the full service contract.

---

## Verification at each phase

| After Phase | Verify |
|---|---|
| 1 | `kubectl get nodes` shows 2 Ready |
| 2 | `kubectl get clustersecretstore gooclaim-azurekv-dev` shows Ready=True |
| 3 | `kubectl get pods -n ingress-nginx` 1/1 Running, public IP assigned |
| 4 | `kubectl get pods -n monitoring` 7+ Running; Grafana HTTPS reachable |
|   | `kubectl get pods -n temporal` 6/7 Running (schema-setup Completed) |
| 5 | `helm template <service>/<chart>` renders cleanly; smoke test on `auth.dev.gooclaim.com` |

---

## Tear-down (full env wipe — be careful)

```bash
# Order matters: helm releases → Terraform destroy
helm uninstall temporal -n temporal
helm uninstall promtail loki kube-prometheus-stack -n monitoring
helm uninstall ingress-nginx -n ingress-nginx
helm uninstall cert-manager -n cert-manager
helm uninstall external-secrets -n external-secrets

cd terraform/environments/dev
terraform destroy

# Note: Key Vault has 90-day soft-delete. Use `az keyvault purge` if you
# need the name back within retention period.
```

---

## Gotchas + lessons learned

| Issue | Fix |
|---|---|
| AKS apply 400 `K8sVersionNotSupported` | Check `az aks get-versions --location centralindia`; default to v1.34 (Azure's recommended) — `1.29` not supported in centralindia at time of writing |
| terraform.tfvars overrides variables.tf defaults silently | Always sync both — tfvars wins |
| Azure PG `extension "btree_gin" not allow-listed` | Set `azure.extensions` Postgres parameter (in our postgres module) |
| Grafana OOMKill loop | Default 256Mi was too low for v13.x; bumped to 768Mi |
| Grafana Multi-Attach error on upgrade | RWO PVC + RollingUpdate: set `maxSurge: 0, maxUnavailable: 1` |
| Temporal `Namespace default is not found` | Register manually via `tctl namespace create default` or use chart's `server.config.namespaces.create=true` |
| cert-manager helm upgrade webhook conflict | Use `--server-side` (default) — AKS adds an admissionsenforcer that owns the webhook field |
| Cloudflare orange-cloud breaks ACME HTTP-01 | Set DNS records to grey-cloud (DNS only) — switch to DNS-01 if you want orange-cloud later |

---

## Files referenced by this runbook

```
terraform/modules/{aks,keyvault,postgres,redis,storage,workload-identity,acr}/
terraform/environments/dev/{main,backend,variables,terraform.tfvars}.tf
helm/external-secrets/{values-dev,cluster-secret-store}.yaml
helm/cert-manager/{values-dev,cluster-issuers}.yaml
helm/ingress-nginx/values-dev.yaml
helm/kube-prometheus-stack/{values-dev,ingress-grafana}.yaml
helm/loki/values-dev.yaml
helm/promtail/values-dev.yaml
helm/temporal/{values-dev,temporal-pg-secret,ingress-web}.yaml
templates/helm/gooclaim-service/  ← golden chart for services
```

---

**Last verified:** 2026-05-13 (Day 6) by dev environment build-out.
**Next test:** Recreate from scratch on nprd Week 6.
