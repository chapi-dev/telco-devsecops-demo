# Demo script — 15–20 min walkthrough

> Mirrors §3 of `demo-telco-devsecops-azure.txt`. Adjust pacing as needed.

## [0:00] Context (1 min)

- Open the PDF cover (`GitHub for VNF and CNF Lifecycle Management`).
- "Everything we'll see lives in GitHub: chart + workflow + policy + IaC.
  One repo, one PR flow, VNF and CNF treated identically."

## [2:00] CI · build + sign + SBOM (4 min)

- Open [`.github/workflows/ci-cnf.yml`](../.github/workflows/ci-cnf.yml).
- Make a trivial commit on `charts/demo-upf/values.yaml` (e.g. bump
  `replicaCount` from 2 → 3) and push.
- Walk through the running workflow:
  1. `helm lint` + `helm dependency update`
  2. Render & validate with `kubeconform`
  3. `helm package`
  4. Trivy filesystem scan → SARIF in **Security → Code scanning**
  5. `syft` → SBOM SPDX
  6. `azure/login@v2` via OIDC (no client secret)
  7. `helm push oci://acrtelcodemo.azurecr.io/charts`
  8. `cosign sign` (keyless) + `cosign attest --type spdxjson`
  9. `actions/attest-build-provenance@v2` → SLSA Level 3
- In ACR show the chart, the `.sig` and the `.att` blobs.
- Run locally:
  ```bash
  cosign verify \
    --certificate-identity-regexp 'https://github.com/chapi-dev/telco-devsecops-demo/.*' \
    --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
    acrtelcodemo.azurecr.io/charts/demo-upf:1.0.0
  ```

## [6:00] GHAS (3 min)

- **Security tab**:
  - CodeQL findings on `src/demo-nf` (operator).
  - Secret scanning with the **custom patterns** for `IMSI` / `SUPI` /
    `K` / `OPc` documented in [SECRET_SCANNING.md](SECRET_SCANNING.md). Push a
    file containing a fake IMSI like `123456789012345` → push protection
    blocks the push.
  - Dependency Review on a PR that bumps `cert-manager` to a CVE-affected
    version.
  - Export the SBOM (SPDX) from **Security → SBOM**.

## [9:00] Dependabot Helm (2 min)

- Open [`.github/dependabot.yml`](../.github/dependabot.yml) — five ecosystems:
  Helm, Docker, Go, Actions, Terraform.
- Open the pre-baked Dependabot PR that bumps a subchart in
  `charts/demo-upf/Chart.yaml`. The full CI suite re-runs on the PR.

## [11:00] GitOps to AKS (4 min)

- `kubectl get applications -n argocd` (use `argocd-cli` if available).
- Port-forward the Argo CD UI:
  ```bash
  kubectl -n argocd port-forward svc/argocd-server 8080:443
  ```
- Open a PR changing `replicaCount: 2 → 3` in
  [`gitops/envs/dev/values.yaml`](../gitops/envs/dev/values.yaml).
- Merge → Argo CD reconciles in seconds.
- Show the [`ApplicationSet`](../gitops/argocd/applicationset.yaml) — the
  same pattern fans out to 1,200 edge clusters in production.

## [15:00] Policy enforcement (3 min)

- Show [`policy/kyverno/verify-cosign.yaml`](../policy/kyverno/verify-cosign.yaml).
- Try to deploy an unsigned `nginx`:
  ```bash
  kubectl run pwn --image=docker.io/library/nginx:latest
  ```
  → Kyverno rejects it (no Sigstore signature, image not from trusted ACR).
- Deploy the signed chart via Argo CD → admitted.

## [18:00] Wrap (2 min)

- Show the **Capability → GitHub feature → Outcome** table from the deck (page 13).
- "From upstream CVE to N edge clusters in minutes — signed, gated, auditable."
