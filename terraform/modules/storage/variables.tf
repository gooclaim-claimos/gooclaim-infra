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

variable "public_network_access_enabled" {
  description = "Allow public access. true for dev; false for nprd/prod (private endpoint)."
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "CIDR ranges allowed to reach the account when public access is enabled"
  type        = list(string)
  default     = []
}

variable "containers" {
  description = "Blob containers to create (lowercase, 3-63 chars, alphanumeric + dashes)"
  type        = list(string)
  default     = ["documents", "exports", "backups", "loki-chunks"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
