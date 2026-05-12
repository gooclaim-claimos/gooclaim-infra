output "account_id" {
  description = "Storage account resource ID"
  value       = azurerm_storage_account.main.id
}

output "account_name" {
  description = "Storage account name (gooclaimapp<env>)"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint (https://<name>.blob.core.windows.net/)"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary access key (sensitive — store in Key Vault; prefer Managed Identity)"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "container_names" {
  description = "Names of containers provisioned"
  value       = [for c in azurerm_storage_container.containers : c.name]
}
