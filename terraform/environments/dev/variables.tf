variable "environment" {
  description = "Environment name (dev / nprd / prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "nprd", "prod"], var.environment)
    error_message = "environment must be one of: dev, nprd, prod"
  }
}

variable "resource_group_name" {
  description = "Resource group where all dev resources live"
  type        = string
  default     = "gooclaim-rg-dev"
}

variable "location" {
  description = "Azure region — locked to centralindia per DPDP §16"
  type        = string
  default     = "centralindia"
  validation {
    condition     = var.location == "centralindia"
    error_message = "v1.0 is locked to centralindia (Mumbai) per DPDP §16 data residency mandate."
  }
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Use `az aks get-versions --location centralindia` to check supported. Default = Azure's recommended stable for the region."
  type        = string
  default     = "1.34"
}

variable "system_node_count" {
  description = "Initial node count for system pool (dev = 2)"
  type        = number
  default     = 2
}

variable "system_node_min_count" {
  description = "Minimum nodes for cluster autoscaler"
  type        = number
  default     = 2
}

variable "system_node_max_count" {
  description = "Maximum nodes for cluster autoscaler"
  type        = number
  default     = 4
}

variable "system_node_vm_size" {
  description = "VM SKU for system nodes (dev = smallest sensible)"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_ip_allowlist" {
  description = "Admin/developer public IPs allowed to reach KV / PG / Redis / Storage directly (dev only). Empty = AzureServices bypass only. Each entry should be a single IP (no CIDR — modules append /32 where needed)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    env           = "dev"
    owner         = "gooclaim"
    "cost-center" = "pilot"
    "managed-by"  = "terraform"
  }
}
