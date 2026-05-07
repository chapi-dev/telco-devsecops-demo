# Terraform — Telco DevSecOps Demo Infra

Provisions the one-time Azure footprint described in `docs/SETUP.md`:

- Resource Group `rg-telco-demo` (West Europe)
- Premium ACR `acrtelcodemo` (Cosign-friendly, OCI Helm)
- AKS `aks-telco-demo` with OIDC issuer + Workload Identity + Cilium network policy
- User-Assigned Managed Identity `mi-github-oidc`
- Federated credentials for `main` and `pull_request` GitHub events
- Role assignments: `AcrPull` (AKS kubelet), `AcrPush` (MI), `AKS Cluster User` (MI)

## Usage

```bash
az login
az account set --subscription <YOUR_SUBSCRIPTION_ID>

terraform init
terraform plan  -var "github_owner=chapi-dev"
terraform apply -var "github_owner=chapi-dev"
```

After apply, copy these outputs into GitHub repo secrets:

| Output | GitHub secret |
|--------|---------------|
| `github_managed_identity_client_id` | `AZURE_CLIENT_ID` |
| `azure_tenant_id` | `AZURE_TENANT_ID` |
| `az account show --query id -o tsv` | `AZURE_SUBSCRIPTION_ID` |

## Notes

- ACR is Premium because Cosign signatures + content trust require Premium tier.
- AKS uses Cilium network policy (eBPF) to align with the deck's "networking as
  code" story (Multus + Cilium + SR-IOV mentioned on page 10).
- For a real edge deployment you would also enable Multus add-on
  (`--network-plugin azure --network-dataplane cilium --network-policy cilium`)
  plus `multus` add-on; left out of the demo to keep `terraform apply` short.
