# =============================================================================
# Gooclaim — dev environment Azure infrastructure
# =============================================================================
#
# This composition wires together the modular Azure resources for the
# `dev` environment per Gooclaim_Cloud.md §3 Phase 2.
#
# What this deploys:
#   • AKS cluster + Log Analytics workspace          (Day 1)
#   • Key Vault                                       (Day 2)
#   • Postgres Flexible Server                        (Day 2)
#   • Redis Cache (Basic C0)                          (Day 2)
#   • Storage Account (app blob — separate from tfstate) (Day 2)
#   • Workload Identity for ESO                       (Day 2)
#
# Yet to be added (Day 3+):
#   • Virtual Network + subnets (for nprd/prod private endpoints)
#   • Per-service Workload Identities (auth, gateway, ...)
#   • Public DNS records + cert-manager DNS01 hookup
#   • Secret-writes to Key Vault (composition-level azurerm_key_vault_secret)
#
# Apply order:
#   terraform init    # picks up new providers (random)
#   terraform plan    # review all resources
#   terraform apply   # provisions ~10-15 min (Postgres slowest)
#
# =============================================================================

# ─── Data sources ─────────────────────────────────────────────────────────────

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# Lookup the gooclaim-admins AAD group for KV admin + PG AAD admin assignment
data "azuread_group" "admins" {
  display_name = "gooclaim-admins"
}

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

# ─── Key Vault ────────────────────────────────────────────────────────────────

module "keyvault" {
  source = "../../modules/keyvault"

  environment           = var.environment
  location              = data.azurerm_resource_group.main.location
  resource_group_name   = data.azurerm_resource_group.main.name
  tenant_id             = data.azurerm_client_config.current.tenant_id
  deployer_principal_id = data.azuread_group.admins.object_id

  public_network_access_enabled = true
  allowed_ip_ranges             = [for ip in var.admin_ip_allowlist : "${ip}/32"]

  tags = var.tags
}

# ─── Postgres Flexible Server ────────────────────────────────────────────────

module "postgres" {
  source = "../../modules/postgres"

  environment              = var.environment
  location                 = data.azurerm_resource_group.main.location
  resource_group_name      = data.azurerm_resource_group.main.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  aad_admin_object_id      = data.azuread_group.admins.object_id
  aad_admin_principal_name = "gooclaim-admins"

  public_network_access_enabled = true
  allowed_admin_ips             = var.admin_ip_allowlist

  tags = var.tags
}

# ─── Redis Cache ──────────────────────────────────────────────────────────────

module "redis" {
  source = "../../modules/redis"

  environment         = var.environment
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  public_network_access_enabled = true
  allowed_admin_ips             = var.admin_ip_allowlist

  tags = var.tags
}

# ─── Storage Account (app blob) ──────────────────────────────────────────────

module "storage" {
  source = "../../modules/storage"

  environment         = var.environment
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  public_network_access_enabled = true
  allowed_ip_ranges             = var.admin_ip_allowlist

  tags = var.tags
}

# ─── Workload Identity for External Secrets Operator ─────────────────────────

module "wi_eso" {
  source = "../../modules/workload-identity"

  environment               = var.environment
  location                  = data.azurerm_resource_group.main.location
  resource_group_name       = data.azurerm_resource_group.main.name
  identity_name             = "eso"
  aks_oidc_issuer_url       = module.aks.oidc_issuer_url
  service_account_namespace = "external-secrets"
  service_account_name      = "external-secrets"
  key_vault_id              = module.keyvault.vault_id

  tags = var.tags
}

# ─── Outputs ─────────────────────────────────────────────────────────────────

output "aks_cluster_name" {
  description = "Name of the provisioned AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity federation"
  value       = module.aks.oidc_issuer_url
}

output "aks_node_resource_group" {
  description = "Auto-created node RG (Azure-managed)"
  value       = module.aks.node_resource_group
}

output "key_vault_uri" {
  description = "Key Vault DNS URI (use in ESO ClusterSecretStore CRD)"
  value       = module.keyvault.vault_uri
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.keyvault.vault_name
}

output "postgres_fqdn" {
  description = "Postgres server FQDN"
  value       = module.postgres.fqdn
}

output "postgres_admin_login" {
  description = "Postgres admin login (password lives in tfstate as sensitive — write to AKV next)"
  value       = module.postgres.admin_login
}

output "redis_hostname" {
  description = "Redis hostname"
  value       = module.redis.hostname
}

output "redis_ssl_port" {
  description = "Redis SSL port"
  value       = module.redis.ssl_port
}

output "storage_account_name" {
  description = "App storage account name"
  value       = module.storage.account_name
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = module.storage.primary_blob_endpoint
}

output "wi_eso_client_id" {
  description = "Client ID for ESO Workload Identity — annotate this on the K8s SA"
  value       = module.wi_eso.client_id
}

output "subscription_id" {
  description = "Azure subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "tenant_id" {
  description = "Azure AD tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}
