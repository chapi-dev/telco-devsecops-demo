<#
.SYNOPSIS
  PowerShell version of bootstrap-azure.sh.

.EXAMPLE
  $env:GITHUB_OWNER = "chapi-dev"
  $env:SUBSCRIPTION_ID = "<sub-id>"
  ./scripts/bootstrap-azure.ps1
#>

[CmdletBinding()]
param(
  [string]$GitHubOwner = $env:GITHUB_OWNER ? $env:GITHUB_OWNER : "chapi-dev",
  [string]$GitHubRepo  = "telco-devsecops-demo",
  [string]$Location    = "westeurope",
  [string]$Rg          = "rg-telco-demo",
  [string]$Acr         = "acrtelcodemo",
  [string]$Aks         = "aks-telco-demo",
  [string]$Mi          = "mi-github-oidc"
)

$ErrorActionPreference = 'Stop'

if ($env:SUBSCRIPTION_ID) {
  az account set --subscription $env:SUBSCRIPTION_ID
}

Write-Host "==> Resource group"
az group create -n $Rg -l $Location -o none

Write-Host "==> ACR (Premium)"
az acr create -g $Rg -n $Acr --sku Premium -o none

Write-Host "==> AKS"
az aks create -g $Rg -n $Aks `
  --node-count 2 --node-vm-size Standard_D4s_v5 `
  --enable-oidc-issuer --enable-workload-identity `
  --network-plugin azure --network-dataplane cilium --network-policy cilium `
  --attach-acr $Acr -o none

Write-Host "==> Managed identity"
az identity create -g $Rg -n $Mi -o none
$MiClientId = az identity show -g $Rg -n $Mi --query clientId -o tsv
$TenantId   = az account show --query tenantId -o tsv
$SubId      = az account show --query id -o tsv

Write-Host "==> Federated credentials"
az identity federated-credential create `
  --name gh-main --identity-name $Mi --resource-group $Rg `
  --issuer "https://token.actions.githubusercontent.com" `
  --subject "repo:$GitHubOwner/$GitHubRepo`:ref:refs/heads/main" `
  --audiences "api://AzureADTokenExchange" -o none

az identity federated-credential create `
  --name gh-pr --identity-name $Mi --resource-group $Rg `
  --issuer "https://token.actions.githubusercontent.com" `
  --subject "repo:$GitHubOwner/$GitHubRepo`:pull_request" `
  --audiences "api://AzureADTokenExchange" -o none

Write-Host "==> Role assignments"
$AcrId       = az acr show -g $Rg -n $Acr --query id -o tsv
$AksId       = az aks show -g $Rg -n $Aks --query id -o tsv
$PrincipalId = az identity show -g $Rg -n $Mi --query principalId -o tsv

az role assignment create --assignee-object-id $PrincipalId `
  --assignee-principal-type ServicePrincipal `
  --role "AcrPush" --scope $AcrId -o none

az role assignment create --assignee-object-id $PrincipalId `
  --assignee-principal-type ServicePrincipal `
  --role "Azure Kubernetes Service Cluster User Role" --scope $AksId -o none

Write-Host @"

==> Done. Add these GitHub repo secrets:

  AZURE_CLIENT_ID=$MiClientId
  AZURE_TENANT_ID=$TenantId
  AZURE_SUBSCRIPTION_ID=$SubId

  gh secret set AZURE_CLIENT_ID -b "$MiClientId"
  gh secret set AZURE_TENANT_ID -b "$TenantId"
  gh secret set AZURE_SUBSCRIPTION_ID -b "$SubId"
"@
