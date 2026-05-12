# =============================================================================
# Module: Azure Storage Account (Gooclaim platform blob store)
# =============================================================================
#
# Provisions:
#   • Storage Account separate from the Terraform state account
#   • StorageV2, LRS for dev/nprd, GRS for prod
#   • TLS 1.2 minimum, public access disabled at blob level
#   • Blob versioning + soft-delete (30d) enabled
#   • Default containers: documents / exports / backups / loki-chunks
#
# Used for:
#   • L2 Truth Layer document caching
#   • L7 Loki log chunk storage (chunks_storage_config: azure)
#   • L4 export bundles + audit ledger backup snapshots
#
# Note: name is global-unique within Azure. We use 'gooclaimapp<env>' which
# stays under the 24-char alphanumeric-lowercase limit.
# =============================================================================

resource "azurerm_storage_account" "main" {
  name                = "gooclaimapp${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  # Hard security defaults
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true # we use keys via AKV — switch to false once all consumers move to MI
  public_network_access_enabled   = var.public_network_access_enabled

  # No hierarchical namespace — we don't need ADLS Gen2 features
  is_hns_enabled = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  # Network ACLs — Allow in dev, Deny in prod (private endpoint elsewhere)
  network_rules {
    default_action             = var.public_network_access_enabled ? "Allow" : "Deny"
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = []
  }

  tags = var.tags
}

# ─── Default containers ──────────────────────────────────────────────────────

resource "azurerm_storage_container" "containers" {
  for_each = toset(var.containers)

  name                  = each.value
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
