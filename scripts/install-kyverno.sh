#!/usr/bin/env bash
# Install Kyverno + the verify-cosign ClusterPolicy.

set -euo pipefail

: "${RG:=rg-telco-demo}"
: "${AKS:=aks-telco-demo}"

az aks get-credentials -g "$RG" -n "$AKS" --overwrite-existing

echo "==> Install Kyverno (Helm)"
helm repo add kyverno https://kyverno.github.io/kyverno || true
helm repo update
helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno --create-namespace \
  --version 3.2.6

kubectl -n kyverno rollout status deploy/kyverno-admission-controller --timeout=5m

echo "==> Apply verify-cosign ClusterPolicy"
kubectl apply -f policy/kyverno/verify-cosign.yaml

echo "==> Status"
kubectl get clusterpolicy verify-cosign-signature
