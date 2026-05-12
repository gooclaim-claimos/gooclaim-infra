# Terraform Module: AKS Cluster

Reusable Terraform module to provision an Azure Kubernetes Service (AKS) cluster for any Gooclaim environment.

## Usage

```hcl
module "aks" {
  source = "../../modules/aks"

  environment           = "dev"            # or "nprd" / "prod"
  resource_group_name   = "gooclaim-rg-dev"
  location              = "centralindia"
  kubernetes_version    = "1.29.0"
  system_node_count     = 2
  system_node_min_count = 2
  system_node_max_count = 4
  system_node_vm_size   = "Standard_D2s_v3"

  tags = {
    env   = "dev"
    owner = "gooclaim"
  }
}
```

## What it creates

| Resource | Purpose |
|----------|---------|
| `azurerm_kubernetes_cluster.main` | The AKS cluster itself |
| `azurerm_log_analytics_workspace.aks` | Diagnostic log destination (when not provided externally) |

## Key features

- **Workload Identity + OIDC** enabled — required for ESO + per-service AAD federation
- **Azure CNI + Calico** — production-grade networking + NetworkPolicy enforcement
- **Autoscaler** — min/max node count for cost control
- **Free SKU for dev/nprd** — Standard SKU only for prod (uptime SLA)
- **30-day log retention** — Log Analytics workspace
- **OMS agent** — Azure Monitor integration

## Per-env sizing recommendation

| Setting | dev | nprd | prod |
|---------|-----|------|------|
| `system_node_count` | 2 | 2 | 3 |
| `system_node_min_count` | 2 | 2 | 3 |
| `system_node_max_count` | 4 | 6 | 10 |
| `system_node_vm_size` | Standard_D2s_v3 | Standard_D4s_v3 | Standard_D8s_v3 |
| `sku_tier` (auto) | Free | Free | Standard |

## Outputs

See [`outputs.tf`](outputs.tf) for the full list. Key outputs:

- `cluster_name` — Pass to `az aks get-credentials`
- `oidc_issuer_url` — Used to configure ESO + Workload Identity federated credentials
- `kube_config_raw` — Sensitive; only for CI/CD use
- `node_resource_group` — Azure auto-creates a separate RG for node VMs

## Cost (dev sizing)

| Component | Monthly cost |
|-----------|--------------|
| Control plane (Free SKU) | ₹0 |
| 2× Standard_D2s_v3 nodes | ~₹4-8K |
| Log Analytics workspace (30-day retention, ~5GB/mo dev) | ~₹500 |
| **Total** | **~₹4.5-8.5K/mo** |

Off-hours scaling (`az aks stop` overnight + weekends) can save ~50%.

## Cross-references

- [`/Gooclaim_Cloud.md` §3 Phase 2.4](../../../../Gooclaim_Cloud.md)
- [`/tasks/cloud-sprint-task/TASK-CLD-204-terraform-aks-module.md`](../../../../tasks/cloud-sprint-task/TASK-CLD-204-terraform-aks-module.md)
