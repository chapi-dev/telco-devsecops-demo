#!/usr/bin/env bash
# One-shot Azure bootstrap for the telco-devsecops-demo.
# Mirrors infra/terraform/* but uses Azure CLI for hands-on demos.
#
# Usage:
#   GITHUB_OWNER=chapi-dev SUBSCRIPTION_ID=<sub> ./scripts/bootstrap-azure.sh

set -euo pipefail

: "${GITHUB_OWNER:=chapi-dev}"
: "${GITHUB_REPO:=telco-devsecops-demo}"
: "${LOCATION:=westeurope}"
: "${RG:=rg-telco-demo}"
: "${ACR:=acrtelcodemo}"
: "${AKS:=aks-telco-demo}"
: "${MI:=mi-github-oidc}"

if [ -n "${SUBSCRIPTION_ID:-}" ]; then
  az account set --subscription "$SUBSCRIPTION_ID"
fi

echo "==> Resource group"
az group create -n "$RG" -l "$LOCATION" -o none

echo "==> ACR (Premium)"
az acr create -g "$RG" -n "$ACR" --sku Premium -o none

echo "==> AKS"
az aks create -g "$RG" -n "$AKS" \
  --node-count 2 --node-vm-size Standard_D4s_v5 \
  --enable-oidc-issuer --enable-workload-identity \
  --network-plugin azure --network-dataplane cilium --network-policy cilium \
  --attach-acr "$ACR" -o none

echo "==> Managed identity"
az identity create -g "$RG" -n "$MI" -o none
MI_CLIENT_ID=$(az identity show -g "$RG" -n "$MI" --query clientId -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SUB_ID=$(az account show --query id -o tsv)

echo "==> Federated credentials (main branch + pull_request)"
az identity federated-credential create \
  --name gh-main \
  --identity-name "$MI" \
  --resource-group "$RG" \
  --issuer https://token.actions.githubusercontent.com \
  --subject "repo:${GITHUB_OWNER}/${GITHUB_REPO}:ref:refs/heads/main" \
  --audiences api://AzureADTokenExchange -o none

az identity federated-credential create \
  --name gh-pr \
  --identity-name "$MI" \
  --resource-group "$RG" \
  --issuer https://token.actions.githubusercontent.com \
  --subject "repo:${GITHUB_OWNER}/${GITHUB_REPO}:pull_request" \
  --audiences api://AzureADTokenExchange -o none

echo "==> Role assignments"
ACR_ID=$(az acr show -g "$RG" -n "$ACR" --query id -o tsv)
AKS_ID=$(az aks show -g "$RG" -n "$AKS" --query id -o tsv)
PRINCIPAL_ID=$(az identity show -g "$RG" -n "$MI" --query principalId -o tsv)

az role assignment create --assignee-object-id "$PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "AcrPush" --scope "$ACR_ID" -o none

az role assignment create --assignee-object-id "$PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Azure Kubernetes Service Cluster User Role" --scope "$AKS_ID" -o none

cat <<EOF

==> Done. Add these as GitHub Actions secrets in
    https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/settings/secrets/actions

  AZURE_CLIENT_ID=$MI_CLIENT_ID
  AZURE_TENANT_ID=$TENANT_ID
  AZURE_SUBSCRIPTION_ID=$SUB_ID

  gh secret set AZURE_CLIENT_ID -b "$MI_CLIENT_ID"
  gh secret set AZURE_TENANT_ID -b "$TENANT_ID"
  gh secret set AZURE_SUBSCRIPTION_ID -b "$SUB_ID"
EOF
