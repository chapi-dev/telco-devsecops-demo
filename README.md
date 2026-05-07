# telco-devsecops-demo

[![ci-cnf](https://github.com/chapi-dev/telco-devsecops-demo/actions/workflows/ci-cnf.yml/badge.svg)](https://github.com/chapi-dev/telco-devsecops-demo/actions/workflows/ci-cnf.yml)
[![codeql](https://github.com/chapi-dev/telco-devsecops-demo/actions/workflows/codeql.yml/badge.svg)](https://github.com/chapi-dev/telco-devsecops-demo/actions/workflows/codeql.yml)

> **Live, end-to-end implementation of the reference deck
> "GitHub for VNF and CNF Lifecycle Management"** — Continuous Integration ·
> Continuous Delivery · Continuous Validation · Security Validation ·
> Dependency Management · Deployable IaC, all on Azure (AKS + ACR) with GitHub
> as the central substrate.

## What it shows

| Capability | GitHub feature | This repo |
|------------|----------------|-----------|
| Continuous Integration | Actions · matrix · OIDC · self-hosted runners | [`.github/workflows/ci-cnf.yml`](.github/workflows/ci-cnf.yml) |
| Continuous Delivery | Argo CD · Flux · Nephio Porch | [`gitops/argocd/applicationset.yaml`](gitops/argocd/applicationset.yaml) |
| Continuous Validation | Required checks · environments · CNF Test Suite · OPA | [`policy/opa/conftest.rego`](policy/opa/conftest.rego) |
| Security Validation | GHAS — CodeQL · Secret Scanning · Dep Review | [`.github/workflows/codeql.yml`](.github/workflows/codeql.yml) · [`docs/SECRET_SCANNING.md`](docs/SECRET_SCANNING.md) |
| Supply chain | Cosign · SLSA L3 · SBOM (SPDX / CycloneDX) | [`ci-cnf.yml` cosign + attest steps](.github/workflows/ci-cnf.yml) |
| Dependency mgmt | Dependabot Helm (2025) · Docker · Actions · Terraform · Go | [`.github/dependabot.yml`](.github/dependabot.yml) |
| Deployable IaC | Terraform (AKS + ACR + MI + Federated Cred) | [`infra/terraform/`](infra/terraform/) |
| Networking as code | Multus secondary networks (N3 / N6) | [`charts/demo-upf/templates/networkattachmentdefinition.yaml`](charts/demo-upf/templates/networkattachmentdefinition.yaml) |
| Control plane as code | Kubernetes Operators (CRD + reconciler) | [`src/demo-nf/`](src/demo-nf/) |
| Policy enforcement | Kyverno verify-cosign + OPA conftest | [`policy/kyverno/verify-cosign.yaml`](policy/kyverno/verify-cosign.yaml) |

## Repository layout

```
telco-devsecops-demo/
├── .github/
│   ├── workflows/
│   │   ├── ci-cnf.yml                # build + scan + SBOM + sign + push Helm chart
│   │   ├── build-vnf-iso.yml         # Packer + Cosign attest (legacy VNF)
│   │   ├── codeql.yml                # SAST on Go operator
│   │   └── security-reusable.yml     # Trivy + Checkov, callable across NF repos
│   ├── dependabot.yml                # Helm + Docker + Go + Actions + Terraform
│   ├── secret_scanning.yml           # IMSI / SUPI / K / OPc patterns (documented)
│   └── CODEOWNERS
├── charts/
│   └── demo-upf/                     # 5G UPF Helm chart (Multus, PSS-restricted)
├── src/
│   └── demo-nf/                      # Go operator stub: CRD + reconciler + main
├── infra/
│   └── terraform/                    # AKS + ACR + Managed Identity + Fed Cred
├── gitops/
│   ├── argocd/applicationset.yaml    # Fan-out to N clusters
│   └── envs/{dev,prod-edge-london}/  # Environment-specific values overrides
├── policy/
│   ├── kyverno/verify-cosign.yaml    # Enforce Sigstore at admission
│   └── opa/conftest.rego             # PSS, image trust, no-:latest, requests req'd
├── scripts/                          # bootstrap-azure.{sh,ps1}, install-{argocd,kyverno}.sh
└── docs/
    ├── DEMO_SCRIPT.md                # 15–20 min walkthrough
    ├── ARCHITECTURE.md               # How everything wires together
    ├── SETUP.md                      # One-time Azure + GitHub setup
    └── SECRET_SCANNING.md            # IMSI / SUPI / K / OPc custom patterns
```

## Quickstart

### 1. Provision Azure (one-time, ~10 min)

```bash
# Either Terraform...
cd infra/terraform && terraform init && terraform apply -var "github_owner=chapi-dev"

# ...or pure Azure CLI
GITHUB_OWNER=chapi-dev ./scripts/bootstrap-azure.sh
```

Both paths produce three values you set as **GitHub Actions secrets**:

```
gh secret set AZURE_CLIENT_ID -b "<managed-identity-client-id>"
gh secret set AZURE_TENANT_ID -b "<tenant-id>"
gh secret set AZURE_SUBSCRIPTION_ID -b "<sub-id>"
```

### 2. Install GitOps + policy on AKS

```bash
./scripts/install-argocd.sh
./scripts/install-kyverno.sh
```

### 3. Trigger the demo

Push any change to `main` → CI runs `helm lint → kubeconform → trivy → syft →
helm push (OCI) → cosign sign → cosign attest SBOM → SLSA build provenance` →
Argo CD reconciles → Kyverno verifies the Sigstore signature at admission.

See [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md) for the full 15–20 min walkthrough.

## Verifying the supply chain locally

```bash
cosign verify \
  --certificate-identity-regexp 'https://github.com/chapi-dev/telco-devsecops-demo/.*' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  acrtelcodemo.azurecr.io/charts/demo-upf:1.0.0
```

## Industry references implemented

- **Vodafone Telco Cloud** (OpenShift + GitOps for 5G) — same Argo CD + PR-gated reconciliation pattern.
- **Nephio R6** (LF Networking) — KRM intent automation, `ApplicationSet` mirrors variant-per-site fan-out.
- **CNCF CNF WG** — "everything as code, GitOps for CNFs" requirement.
- **LFN Anuket / O-RAN SC / Sylva / free5GC / Open Air Interface / Magma** — same GitHub-native CI pattern.

## License

[Apache-2.0](LICENSE)
