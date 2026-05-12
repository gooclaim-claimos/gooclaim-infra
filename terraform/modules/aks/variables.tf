variable "environment" {
  description = "Environment name (dev / nprd / prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where AKS will be created"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version"
  type        = string
  default     = "1.29.0"
}

variable "system_node_count" {
  description = "Initial node count for system pool"
  type        = number
  default     = 2
}

variable "system_node_min_count" {
  description = "Minimum nodes for autoscaler"
  type        = number
  default     = 2
}

variable "system_node_max_count" {
  description = "Maximum nodes for autoscaler"
  type        = number
  default     = 4
}

variable "system_node_vm_size" {
  description = "VM SKU for system nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "log_analytics_workspace_id" {
  description = "Optional pre-existing Log Analytics workspace ID. When null, module creates its own."
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
