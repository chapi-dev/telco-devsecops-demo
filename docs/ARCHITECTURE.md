# Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                  GitHub                                      │
│                                                                              │
│  Actions (CI)            GHAS                       GitOps source-of-truth   │
│  ─────────────           ─────                      ──────────────────────   │
│  ci-cnf.yml              CodeQL  (Go)               charts/demo-upf/         │
│  build-vnf-iso.yml       Secret Scanning + IMSI/K   gitops/envs/{dev,prod}   │
│  codeql.yml              Dependency Review          policy/kyverno/*         │
│  security-reusable.yml   SBOM export (SPDX)         infra/terraform/         │
│                                                                              │
│  Dependabot (Helm/Docker/Go/Actions/Terraform)                               │
│  Sigstore keyless signing + SLSA L3 attestations                             │
└─────────────────────────────────┬────────────────────────────────────────────┘
                                  │  OIDC (no static secrets)
                                  ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                                  Azure                                       │
│                                                                              │
│  rg-telco-demo                                                               │
│  ├── acrtelcodemo  (Premium ACR)  ◀── helm push (OCI) + cosign sign/attest   │
│  ├── aks-telco-demo (AKS, Cilium NP, OIDC issuer, Workload Identity)         │
│  │     ├── argocd      ApplicationSet → fan-out to envs                      │
│  │     ├── kyverno     ClusterPolicy verify-cosign-signature                 │
│  │     └── demo-upf-*  Pods running the chart, Multus N3/N6                  │
│  └── mi-github-oidc  (User-assigned MI · Federated Cred ↔ GitHub OIDC)       │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Trust chain

```
Developer commit
   │
   ▼
GitHub Actions (ci-cnf.yml) ── OIDC ──► Azure (push to ACR)
   │                              │
   │                              ▼
   │                        ACR stores: chart.tgz, .sig, .att (SBOM), provenance
   │
   ▼
Argo CD (in AKS) pulls from GitHub  ── helm template ──►
   │
   ▼
Kyverno admission webhook
   │
   ├── Verifies cosign signature subject matches:
   │     https://github.com/chapi-dev/telco-devsecops-demo/.github/workflows/ci-cnf.yml@refs/heads/main
   │
   └── Allows the Pod only if signature + Rekor entry are valid.
```

## Why each piece

- **OIDC federation, no client secrets**: GitHub mints short-lived tokens that
  Azure trusts because of the federated credential (page 7 of the deck).
- **Sigstore keyless**: relies on GitHub's own OIDC, so signatures are tied to
  *this* workflow, on *this* commit, in *this* branch (page 7).
- **Multus + Cilium**: aligns with the deck's "networking as code" message
  (page 10) — N3 / N6 are templated as `NetworkAttachmentDefinition` CRs.
- **ApplicationSet**: same pattern Vodafone, Nephio and Sylva use to fan out
  to thousands of edge clusters (pages 5, 11–12).
- **Kyverno verify-cosign**: closes the loop — without it, signatures are
  cryptographic theatre. Now no Pod ships from `acrtelcodemo.azurecr.io`
  without a signature whose subject matches the CI workflow.
