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

variable "identity_name" {
  description = "Short identifier for this UAMI (e.g. 'eso', 'auth', 'gateway'). Appended to gooclaim-wi-<name>-<env>."
  type        = string
}

variable "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster (from aks module output)"
  type        = string
}

variable "service_account_namespace" {
  description = "K8s namespace of the ServiceAccount this identity federates with"
  type        = string
}

variable "service_account_name" {
  description = "Name of the K8s ServiceAccount this identity federates with"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault this identity gets 'Key Vault Secrets User' on"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
