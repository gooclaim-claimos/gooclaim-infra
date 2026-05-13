output "registry_id" {
  description = "ACR resource ID"
  value       = azurerm_container_registry.main.id
}

output "registry_name" {
  description = "ACR name (without .azurecr.io suffix)"
  value       = azurerm_container_registry.main.name
}

output "login_server" {
  description = "Full login server hostname — use for docker push/pull (e.g., gooclaimacrdev.azurecr.io)"
  value       = azurerm_container_registry.main.login_server
}
