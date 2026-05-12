# =============================================================================
# Module: Azure Key Vault (Gooclaim platform secrets store)
# =============================================================================
#
# Provisions:
#   • Key Vault with RBAC authorization (modern model — no access policies)
#   • Soft-delete: 90 days (mandatory; cannot be disabled in new vaults)
#   • Purge protection: prod only (irreversible — dev needs the option to wipe)
#   • Network ACLs: default-allow for dev, default-deny + private endpoint
#     for nprd/prod (caller sets var.public_network_access_enabled)
#
# Secret naming convention (composition writes these — not the module):
#   gooclaim-<service>-<key>  e.g. gooclaim-auth-jwt-private-key
#
# Cost: ~₹0.03 per 10K operations + ₹0.20/secret/month. Negligible.
# =============================================================================

resource "azurerm_key_vault" "main" {
  name                = "gooclaim-kv-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tenant_id                  = var.tenant_id
  sku_name                   = var.environment == "prod" ? "premium" : "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = var.environment == "prod"

  # RBAC auth model — never use access policies
  enable_rbac_authorization = true

  # Public access posture
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    default_action = var.public_network_access_enabled ? "Allow" : "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_ranges
  }

  tags = var.tags
}

# ─── Grant the deploying principal full admin so we can write secrets ────────
# Required for the Terraform composition to write azurerm_key_vault_secret.

resource "azurerm_role_assignment" "deployer_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.deployer_principal_id
}
