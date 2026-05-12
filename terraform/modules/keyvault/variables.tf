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
  description = "Azure AD tenant ID (typically data.azurerm_client_config.current.tenant_id)"
  type        = string
}

variable "deployer_principal_id" {
  description = "Object ID of the principal running Terraform — granted Key Vault Administrator on this vault"
  type        = string
}

variable "public_network_access_enabled" {
  description = "Allow public network access. True for dev (with IP allowlist); false for nprd/prod (private endpoint only)."
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "CIDR ranges allowed to reach the vault when public access is enabled. Empty = AzureServices bypass only."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
