output "resource_group" {
  value = azurerm_resource_group.demo.name
}

output "acr_login_server" {
  value = azurerm_container_registry.demo.login_server
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.demo.name
}

output "aks_oidc_issuer" {
  value = azurerm_kubernetes_cluster.demo.oidc_issuer_url
}

output "github_managed_identity_client_id" {
  description = "Set this as GitHub Actions secret AZURE_CLIENT_ID."
  value       = azurerm_user_assigned_identity.github.client_id
}

output "azure_tenant_id" {
  description = "Set this as GitHub Actions secret AZURE_TENANT_ID."
  value       = azurerm_user_assigned_identity.github.tenant_id
}
