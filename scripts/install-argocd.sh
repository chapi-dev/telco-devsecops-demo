#!/usr/bin/env bash
# Install Argo CD on the AKS cluster and apply the demo ApplicationSet.

set -euo pipefail

: "${RG:=rg-telco-demo}"
: "${AKS:=aks-telco-demo}"

echo "==> Get AKS credentials"
az aks get-credentials -g "$RG" -n "$AKS" --overwrite-existing

echo "==> Install Argo CD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Wait for Argo CD server"
kubectl -n argocd rollout status deploy/argocd-server --timeout=5m

echo "==> Apply ApplicationSet"
kubectl apply -f gitops/argocd/applicationset.yaml

echo
echo "==> Get initial admin password"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo
echo "Port-forward UI:  kubectl -n argocd port-forward svc/argocd-server 8080:443"
