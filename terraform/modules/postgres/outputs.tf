output "server_id" {
  description = "Postgres server resource ID"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  description = "Postgres server name (gooclaim-pg-<env>)"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "fqdn" {
  description = "Fully qualified DNS name (use in connection strings)"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "admin_login" {
  description = "Postgres admin username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "admin_password" {
  description = "Postgres admin password (sensitive — write to Key Vault, never print)"
  value       = random_password.admin.result
  sensitive   = true
}
