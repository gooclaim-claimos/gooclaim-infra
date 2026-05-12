# =============================================================================
# Module: Azure Cache for Redis (Gooclaim platform queue + cache)
# =============================================================================
#
# Provisions:
#   • Azure Cache for Redis — Basic C0 (250 MB) for dev (₹1.5K/mo)
#   • TLS 1.2 minimum, non-SSL port disabled
#   • Public access (dev only — Private Endpoint in nprd/prod)
#
# Used for:
#   • BullMQ-compatible queue keys (bull:l1_inbox:wait, bull:l5_outbox:wait)
#   • Per-tenant circuit_breaker state
#   • Template registry cache (TTL 300s)
#
# Cost (dev): ~₹1.5K/month
# =============================================================================

resource "azurerm_redis_cache" "main" {
  name                = "gooclaim-redis-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  capacity = var.capacity
  family   = var.family
  sku_name = var.sku_name

  # Hard security defaults
  minimum_tls_version           = "1.2"
  non_ssl_port_enabled          = false
  public_network_access_enabled = var.public_network_access_enabled

  redis_configuration {
    # Disable persistence in dev (we treat Redis as ephemeral)
    rdb_backup_enabled = false
    # No external auth — primary access key only
    authentication_enabled = true
  }

  tags = var.tags
}

# ─── Firewall rules (dev only — admin IP ranges) ─────────────────────────────

resource "azurerm_redis_firewall_rule" "admin_ip" {
  for_each = toset(var.public_network_access_enabled ? var.allowed_admin_ips : [])

  name                = "admin_${replace(each.value, ".", "_")}"
  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = var.resource_group_name
  start_ip            = each.value
  end_ip              = each.value
}
