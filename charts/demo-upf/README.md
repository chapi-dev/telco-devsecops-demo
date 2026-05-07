# demo-upf

Demo Helm chart simulating a 5G User Plane Function (UPF) for the
"GitHub for VNF and CNF Lifecycle Management" reference demo.

## What it shows

| Capability | Where in this chart |
|------------|--------------------|
| Pinned subcharts (Dependabot Helm) | `Chart.yaml` `dependencies:` |
| Multus secondary networks (N3 / N6) | `templates/networkattachmentdefinition.yaml` |
| 3GPP NF labels | `templates/_helpers.tpl` (`network.3gpp.org/nf-type: UPF`) |
| Pod hardening (PSS-restricted) | `values.yaml` `podSecurityContext` + `securityContext` |
| Prometheus scraping | `values.yaml` `podAnnotations` |
| PFCP / GTP-U / metrics ports | `values.yaml` `service.ports` |
| Sigstore-friendly image refs | OCI repo `acrtelcodemo.azurecr.io/charts/demo-upf` |

## Local rendering

```bash
helm dependency update charts/demo-upf
helm lint charts/demo-upf
helm template demo-upf charts/demo-upf | kubeconform -strict -summary
```

## OCI push (done by CI)

```bash
helm package charts/demo-upf -d dist/
helm push dist/demo-upf-1.0.0.tgz oci://acrtelcodemo.azurecr.io/charts
```

## Sigstore verification at deploy time

Kyverno (see `policy/kyverno/verify-cosign.yaml`) enforces that every Pod from
`acrtelcodemo.azurecr.io/*` carries a valid Sigstore signature whose subject
matches our CI workflow.
