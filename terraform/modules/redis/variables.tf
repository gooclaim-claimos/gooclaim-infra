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

variable "capacity" {
  description = "Cache size code. Basic/Standard: 0=250MB, 1=1GB, 2=2.5GB, 3=6GB, 4=13GB, 5=26GB, 6=53GB"
  type        = number
  default     = 0
}

variable "family" {
  description = "C = Basic/Standard, P = Premium"
  type        = string
  default     = "C"
  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "family must be C (Basic/Standard) or P (Premium)"
  }
}

variable "sku_name" {
  description = "Basic / Standard / Premium"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "sku_name must be Basic, Standard, or Premium"
  }
}

variable "public_network_access_enabled" {
  description = "Allow public network access. true for dev; false for nprd/prod (private endpoint)."
  type        = bool
  default     = true
}

variable "allowed_admin_ips" {
  description = "Individual admin IPs to firewall-allow (only when public access enabled)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
