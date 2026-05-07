# Setup

End-to-end one-time provisioning. Two paths: Terraform (preferred) or pure
Azure CLI script (`scripts/bootstrap-azure.sh`).

## Prerequisites

- Azure subscription where you can create RG / AKS / ACR / Managed Identity.
- `az` CLI logged in (`az login`).
- `terraform >= 1.6` (Terraform path only).
- `gh` CLI logged in to your GitHub user/org.
- The repo `chapi-dev/telco-devsecops-demo` already created (see step 0).

## 0. GitHub repo

```bash
gh repo create chapi-dev/telco-devsecops-demo \
  --public \
  --source=. \
  --remote=origin \
  --push \
  --description "Telco DevSecOps demo on Azure (VNF/CNF lifecycle on GitHub)"
```

Public is required for Sigstore keyless cosign + GHAS to work without a paid
plan.

## 1. Provision Azure

### Option A — Terraform

```bash
cd infra/terraform
terraform init
terraform apply -var "github_owner=chapi-dev"
```

After apply, capture the three outputs:

```bash
terraform output github_managed_identity_client_id   # → AZURE_CLIENT_ID
terraform output azure_tenant_id                     # → AZURE_TENANT_ID
az account show --query id -o tsv                    # → AZURE_SUBSCRIPTION_ID
```

### Option B — Azure CLI script

```bash
GITHUB_OWNER=chapi-dev SUBSCRIPTION_ID=<sub-id> ./scripts/bootstrap-azure.sh
```

It prints the three secret values at the end.

## 2. GitHub Actions secrets

```bash
gh secret set AZURE_CLIENT_ID       -b "<value>"
gh secret set AZURE_TENANT_ID       -b "<value>"
gh secret set AZURE_SUBSCRIPTION_ID -b "<value>"
```

## 3. AKS · Argo CD · Kyverno

```bash
./scripts/install-argocd.sh
./scripts/install-kyverno.sh
```

## 4. GHAS

In **Settings → Code security**:
- Enable **Code scanning** (CodeQL workflow already in repo).
- Enable **Secret scanning** + **Push protection**.
- Add the four custom patterns from [SECRET_SCANNING.md](SECRET_SCANNING.md).

## 5. Branch protection

In **Settings → Branches → Add rule** for `main`:
- Require PR before merge.
- Require status checks: `ci-cnf`, `codeql`.
- Require linear history.
- Require signed commits (recommended).

## 6. Smoke test

Push a trivial change and watch:
- `ci-cnf` runs and signs the chart.
- ACR shows `charts/demo-upf:1.0.0` + `.sig` + `.att`.
- Argo CD picks up the change in `gitops/envs/dev`.
- Kyverno allows the signed Pod.
