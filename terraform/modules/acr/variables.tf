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

variable "sku" {
  description = "ACR SKU. Standard (100 GB) for dev/nprd; Premium (500 GB + geo-replication + CMK + content-trust) for prod."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium"
  }
}

variable "public_network_access_enabled" {
  description = "Allow public network access. true for dev (laptop pushes); false for prod (private endpoint only)."
  type        = bool
  default     = true
}

variable "aks_kubelet_principal_id" {
  description = "Principal ID of the AKS kubelet identity (from AKS module output). Grants AcrPull role."
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
