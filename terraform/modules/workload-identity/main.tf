# =============================================================================
# Module: Workload Identity for External Secrets Operator (ESO)
# =============================================================================
#
# Provisions:
#   • User-Assigned Managed Identity (UAMI) for ESO
#   • Federated credential binding the UAMI to a K8s ServiceAccount
#     via the AKS OIDC issuer (no client secrets — full OIDC trust)
#   • Role grant: "Key Vault Secrets User" on the target Key Vault
#     so ESO can read secrets via Azure Workload Identity flow.
#
# How K8s consumes this:
#   1. Helm install ESO with values:
#        serviceAccount.annotations.azure.workload.identity/client-id = <client_id output>
#        podLabels.azure.workload.identity/use = "true"
#   2. ClusterSecretStore CRD references vault_uri + tenant_id.
#   3. ExternalSecret CRDs reference secrets by AKV name.
#
# This pattern is reusable for any K8s SA → AKV resource binding.
# =============================================================================

resource "azurerm_user_assigned_identity" "main" {
  name                = "gooclaim-wi-${var.identity_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# ─── Federated identity credential (K8s ServiceAccount trust) ────────────────

resource "azurerm_federated_identity_credential" "main" {
  name                = "fed-${var.service_account_namespace}-${var.service_account_name}"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.main.id

  audience = ["api://AzureADTokenExchange"]
  issuer   = var.aks_oidc_issuer_url
  subject  = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
}

# ─── Role assignment: Key Vault Secrets User on the target vault ────────────

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}
