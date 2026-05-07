# User-assigned managed identity that GitHub Actions assumes via OIDC.
resource "azurerm_user_assigned_identity" "github" {
  name                = var.managed_identity_name
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  tags                = var.tags
}

# Federated credential: ties this identity to a specific GitHub repo + branch.
resource "azurerm_federated_identity_credential" "github_main" {
  name                = "gh-main"
  resource_group_name = azurerm_resource_group.demo.name
  parent_id           = azurerm_user_assigned_identity.github.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
}

# Federated credential for pull_request events (CI on PRs).
resource "azurerm_federated_identity_credential" "github_pr" {
  name                = "gh-pull-request"
  resource_group_name = azurerm_resource_group.demo.name
  parent_id           = azurerm_user_assigned_identity.github.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_owner}/${var.github_repo}:pull_request"
}

# Allow the MI to push images and Helm charts to ACR.
resource "azurerm_role_assignment" "github_acr_push" {
  scope                = azurerm_container_registry.demo.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

# Optional: allow the MI to read AKS for kubeconform / smoke tests.
resource "azurerm_role_assignment" "github_aks_user" {
  scope                = azurerm_kubernetes_cluster.demo.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}
