# =============================================================================
# Module: AKS cluster (Gooclaim platform compute layer)
# =============================================================================
#
# Provisions:
#   • Azure Kubernetes Service cluster with system node pool
#   • Workload Identity + OIDC issuer (for ESO + per-service AAD federation)
#   • Calico network policy enforcement
#   • Azure CNI networking
#   • Auto-managed Log Analytics workspace (when not provided externally)
#   • OMS agent for diagnostic streaming
#
# Reusability: pass var.environment + override sizing for nprd / prod.
#
# Cost (dev): ~₹4-8K/month — control plane Free SKU + 2× D2s_v3 nodes
#             autoscaler-bound 2-4. Off-hours scale-down recommended.
# =============================================================================

# ─── Log Analytics workspace (only when not provided externally) ─────────────

resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.log_analytics_workspace_id == null ? 1 : 0
  name                = "gooclaim-aks-${var.environment}-logs"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

locals {
  log_analytics_workspace_id = (
    var.log_analytics_workspace_id != null
    ? var.log_analytics_workspace_id
    : azurerm_log_analytics_workspace.aks[0].id
  )
}

# ─── AKS Cluster ──────────────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "main" {
  name                = "gooclaim-aks-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "gooclaim-aks-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # SKU: Free tier for dev/nprd; Standard for prod (uptime SLA)
  sku_tier = var.environment == "prod" ? "Standard" : "Free"

  # ─── Identity ─────────────────────────────────────────────────────
  identity {
    type = "SystemAssigned"
  }

  # ─── OIDC + Workload Identity ─────────────────────────────────────
  # Required for federated credentials from AAD app to K8s ServiceAccount.
  # ESO will use this to fetch secrets from Azure Key Vault.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # ─── System Node Pool (always-on baseline) ────────────────────────
  default_node_pool {
    name = "system"

    vm_size             = var.system_node_vm_size
    node_count          = var.system_node_count
    enable_auto_scaling = true
    min_count           = var.system_node_min_count
    max_count           = var.system_node_max_count

    os_disk_size_gb = 50
    os_disk_type    = "Managed"
    type            = "VirtualMachineScaleSets"

    # Only system pods on this pool (per Azure best practice)
    only_critical_addons_enabled = false

    # Surge upgrade defaults — match what Azure auto-applies to avoid drift
    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }

    tags = var.tags
  }

  # ─── Networking ───────────────────────────────────────────────────
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = "10.100.0.0/16"
    dns_service_ip    = "10.100.0.10"
  }

  # ─── Add-ons ──────────────────────────────────────────────────────
  oms_agent {
    log_analytics_workspace_id = local.log_analytics_workspace_id
  }

  # ─── Lifecycle ────────────────────────────────────────────────────
  lifecycle {
    ignore_changes = [
      # Autoscaler drift — node count changes outside Terraform's view
      default_node_pool[0].node_count,
    ]
  }

  tags = var.tags
}
