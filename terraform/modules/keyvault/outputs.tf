output "vault_id" {
  description = "Resource ID of the Key Vault (used for RBAC scope + ESO ClusterSecretStore)"
  value       = azurerm_key_vault.main.id
}

output "vault_uri" {
  description = "DNS URI of the Key Vault (https://<name>.vault.azure.net/)"
  value       = azurerm_key_vault.main.vault_uri
}

output "vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}
