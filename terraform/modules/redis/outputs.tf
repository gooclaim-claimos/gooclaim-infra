output "cache_id" {
  description = "Redis cache resource ID"
  value       = azurerm_redis_cache.main.id
}

output "cache_name" {
  description = "Redis cache name (gooclaim-redis-<env>)"
  value       = azurerm_redis_cache.main.name
}

output "hostname" {
  description = "Redis hostname (e.g. gooclaim-redis-dev.redis.cache.windows.net)"
  value       = azurerm_redis_cache.main.hostname
}

output "ssl_port" {
  description = "Redis SSL port (typically 6380)"
  value       = azurerm_redis_cache.main.ssl_port
}

output "primary_access_key" {
  description = "Primary access key (sensitive — store in Key Vault)"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string (sensitive — store in Key Vault)"
  value       = azurerm_redis_cache.main.primary_connection_string
  sensitive   = true
}
