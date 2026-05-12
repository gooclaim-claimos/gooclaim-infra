# =============================================================================
# Gooclaim — dev environment Azure infrastructure
# =============================================================================
#
# This composition wires together the modular Azure resources for the
# `dev` environment per Gooclaim_Cloud.md §3 Phase 2.
#
# What this deploys (Day 1 — AKS only):
#   • Azure Kubernetes Service (AKS) cluster
#   • Log Analytics workspace for AKS diagnostics
#
# To be added in subsequent days (TASK-CLD-205 → 211):
#   • Virtual Network + subnets
#   • Azure Key Vault
#   • Azure Postgres Flexible Server
#   • Azure Cache for Redis
#   • Storage Account (loki / scout / audit)
#   • Workload Identity (AAD app + federated credentials)
#   • Public IP + DNS records
#
# Apply order:
#   terraform init    # Once after writing this file
#   terraform plan    # Review what will be created
#   terraform apply   # Provisions ~15-20 min (AKS slowest)
#
# =============================================================================

# ─── Data sources ─────────────────────────────────────────────────────────────

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# ─── AKS Cluster ──────────────────────────────────────────────────────────────

module "aks" {
  source = "../../modules/aks"

  environment           = var.environment
  resource_group_name   = data.azurerm_resource_group.main.name
  location              = data.azurerm_resource_group.main.location
  kubernetes_version    = var.kubernetes_version
  system_node_count     = var.system_node_count
  system_node_min_count = var.system_node_min_count
  system_node_max_count = var.system_node_max_count
  system_node_vm_size   = var.system_node_vm_size

  tags = var.tags
}

# ─── Outputs ─────────────────────────────────────────────────────────────────

output "aks_cluster_name" {
  description = "Name of the provisioned AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity federation (used by ESO + Workload Identity bindings later)"
  value       = module.aks.oidc_issuer_url
}

output "aks_node_resource_group" {
  description = "Auto-created node RG (Azure-managed)"
  value       = module.aks.node_resource_group
}

output "subscription_id" {
  description = "Azure subscription ID (for downstream module references)"
  value       = data.azurerm_subscription.current.subscription_id
}
