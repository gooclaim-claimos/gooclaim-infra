# =============================================================================
# Module: Postgres Flexible Server (Gooclaim platform RDBMS)
# =============================================================================
#
# Provisions:
#   • PG 16 Flexible Server (single zone, no HA in dev)
#   • Burstable B1ms SKU for dev (₹2-3K/mo); D2ds_v5 for prod
#   • 32 GB storage (auto-grow disabled — stop runaway costs)
#   • Random strong password (caller stores it in Key Vault)
#   • AAD admin: assigned to gooclaim-admins group
#   • Public access: dev=open (firewall-restricted); nprd/prod=disabled
#
# After provision, callers create per-service databases via DB role
# provisioning scripts (provision_db_roles.sql in each service repo).
#
# Cost (dev): ₹2-3K/month + ₹0.50/GB storage
# =============================================================================

resource "random_password" "admin" {
  length      = 32
  special     = true
  min_lower   = 4
  min_upper   = 4
  min_numeric = 4
  min_special = 2
  # Avoid characters Azure rejects in URLs
  override_special = "!#$%&*+-=?@^_"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "gooclaim-pg-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  version    = "16"
  sku_name   = var.sku_name
  storage_mb = var.storage_mb
  # 4-byte storage tier (newer SKU mapping)
  storage_tier = var.storage_tier
  zone         = "1"

  administrator_login    = var.admin_login
  administrator_password = random_password.admin.result

  # Backup retention 7d for dev, 35d for prod (configured via var)
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.environment == "prod"

  # HA off in dev; ZoneRedundant in prod
  dynamic "high_availability" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
    }
  }

  # Public network access — true in dev only
  public_network_access_enabled = var.public_network_access_enabled

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = var.tenant_id
  }

  lifecycle {
    ignore_changes = [
      # AAD password rotates separately; admin password rotation handled via Vault
      administrator_password,
      # Zone may flip during failovers
      zone,
    ]
  }

  tags = var.tags
}

# ─── AAD admin assignment ────────────────────────────────────────────────────
# Maps the gooclaim-admins group as PG AAD admin.

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "admins" {
  server_name         = azurerm_postgresql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  object_id           = var.aad_admin_object_id
  principal_name      = var.aad_admin_principal_name
  principal_type      = "Group"
}

# ─── Firewall rules (dev only — open access to admins for migrations) ───────

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  count            = var.public_network_access_enabled ? 1 : 0
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "admin_ip" {
  for_each = toset(var.public_network_access_enabled ? var.allowed_admin_ips : [])

  name             = "admin-${replace(each.value, ".", "-")}"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

# ─── azure.extensions — allow-list extensions used by platform ───────────────
# Without this, CREATE EXTENSION fails for non-default extensions. Temporal's
# visibility schema needs btree_gin; L3 Knowledge Layer uses vector (pgvector);
# multiple services use pg_trgm / pgcrypto.

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = var.enabled_extensions
}
