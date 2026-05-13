# =============================================================================
# Module: Azure Container Registry (Gooclaim platform image registry)
# =============================================================================
#
# Hosts container images for all Gooclaim services. AKS kubelet identity
# gets `AcrPull` role so pods can pull without imagePullSecrets — no
# credentials in cluster manifests.
#
# Push side (CI/CD):
#   v1.0 dev: developers `az acr login` from laptop, docker push
#   v1.1+:    GitHub Actions workflow with federated credential against
#             a service principal (DOCKER_CONFIG with az acr token)
#
# Pull side (AKS):
#   `azurerm_role_assignment.aks_acrpull` grants AKS kubelet identity
#   AcrPull on the ACR scope. No imagePullSecrets needed in pods.
#
# Cost (dev): Standard SKU ~₹300/mo + storage at ~₹0.5/GB/mo
# =============================================================================

resource "azurerm_container_registry" "main" {
  # Naming: ACR names must be globally unique + alphanumeric only (no dashes)
  name                = "gooclaimacr${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  # Standard SKU: 100 GB storage included, geo-replication not needed for dev
  # Premium would add: geo-replication, customer-managed keys, content trust
  sku = var.sku

  # Disable admin user — modern pattern is AAD/Managed Identity only
  admin_enabled = false

  # Public network access — true for dev (laptop pushes); false in prod (PE only)
  public_network_access_enabled = var.public_network_access_enabled

  # Anonymous pull — never; we want image-pull auditability
  anonymous_pull_enabled = false

  # Note: retention_policy + content trust require Premium SKU. On Standard
  # we rely on manual `az acr repository delete` for cleanup. Switch to
  # Premium in prod for automatic retention.

  tags = var.tags
}

# ─── Grant AKS kubelet identity AcrPull on this ACR ──────────────────────────
# Without this, AKS pods can't pull images from ACR. The kubelet identity is
# the auto-created MI bound to the AKS node pool (different from the AKS
# control-plane identity).

resource "azurerm_role_assignment" "aks_acrpull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = var.aks_kubelet_principal_id
  skip_service_principal_aad_check = true
}
