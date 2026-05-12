output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_id" {
  description = "AKS cluster Azure resource ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_fqdn" {
  description = "AKS cluster fully qualified domain name"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config_raw" {
  description = "Raw kubeconfig — sensitive, use for CI/CD only (humans should use az aks get-credentials)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Admin kubeconfig (bypasses Azure AD) — for break-glass only"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL — REQUIRED for Workload Identity federated credential setup (per-service AAD app trust)"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Kubelet managed identity object ID — used by AKS to pull images, etc."
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "Kubelet managed identity client ID"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
}

output "node_resource_group" {
  description = "Auto-created Azure RG holding AKS node VMs (Azure-managed)"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (created by module or passed in)"
  value       = local.log_analytics_workspace_id
}
