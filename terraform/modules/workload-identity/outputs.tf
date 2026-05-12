output "identity_id" {
  description = "Resource ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "client_id" {
  description = "Client ID of the UAMI — annotate this on the K8s ServiceAccount: azure.workload.identity/client-id"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "principal_id" {
  description = "Principal (object) ID — used for additional RBAC role assignments"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "tenant_id" {
  description = "Tenant ID the UAMI lives in — needed by ESO ClusterSecretStore CRD"
  value       = azurerm_user_assigned_identity.main.tenant_id
}

output "name" {
  description = "Full name of the UAMI"
  value       = azurerm_user_assigned_identity.main.name
}
