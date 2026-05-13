variable "environment" {
  description = "Environment name (dev / nprd / prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "sku_name" {
  description = "Postgres Flexible Server SKU (e.g. B_Standard_B1ms for dev, GP_Standard_D2ds_v5 for prod)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage in MB. Min 32768 (32 GB)."
  type        = number
  default     = 32768
}

variable "storage_tier" {
  description = "Storage tier — P4/P6/P10/P15/P20/P30/P40/P50/P60. P4 = 32GB / 120 IOPS."
  type        = string
  default     = "P4"
}

variable "admin_login" {
  description = "Postgres admin username (used for migrations + DDL only — services use AAD or per-svc roles)"
  type        = string
  default     = "gooclaimadmin"
}

variable "aad_admin_object_id" {
  description = "Object ID of the AAD group/user to assign as PG AAD admin (typically gooclaim-admins group)"
  type        = string
}

variable "aad_admin_principal_name" {
  description = "Display name of the AAD admin (shown in Azure portal)"
  type        = string
  default     = "gooclaim-admins"
}

variable "backup_retention_days" {
  description = "Backup retention window. 7 for dev, 35 for prod."
  type        = number
  default     = 7
}

variable "public_network_access_enabled" {
  description = "Enable public network access. true for dev; false for nprd/prod (use private endpoint)."
  type        = bool
  default     = true
}

variable "enabled_extensions" {
  description = "Postgres extensions to allow-list via `azure.extensions` server parameter. Azure Postgres Flexible Server requires explicit allow-listing — without this, `CREATE EXTENSION` fails for non-default extensions. Comma-separated list, lowercase per PG convention."
  type        = string
  default     = "btree_gin,btree_gist,pg_trgm,pg_stat_statements,uuid-ossp,pgcrypto,vector"
}

variable "allowed_admin_ips" {
  description = "Individual admin IPs to firewall-allow (only used when public access enabled). Excludes the AzureServices bypass which is always added."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
