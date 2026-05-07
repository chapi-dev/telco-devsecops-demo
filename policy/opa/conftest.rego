# Conftest policies for telco-devsecops-demo
# Run with:
#   helm template demo-upf charts/demo-upf | conftest test --policy policy/opa -

package main

# Disallow privileged containers in any deployment.
deny[msg] {
  input.kind == "Deployment"
  some i
  c := input.spec.template.spec.containers[i]
  c.securityContext.privileged == true
  msg := sprintf("Container %q in deployment %q must not be privileged", [c.name, input.metadata.name])
}

# Require runAsNonRoot at pod level.
deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot
  msg := sprintf("Deployment %q must set spec.template.spec.securityContext.runAsNonRoot=true", [input.metadata.name])
}

# Require resources.requests on every container (RAN/MEC capacity guarantee).
deny[msg] {
  input.kind == "Deployment"
  some i
  c := input.spec.template.spec.containers[i]
  not c.resources.requests
  msg := sprintf("Container %q in %q must declare resources.requests", [c.name, input.metadata.name])
}

# Forbid the `latest` tag.
deny[msg] {
  input.kind == "Deployment"
  some i
  c := input.spec.template.spec.containers[i]
  endswith(c.image, ":latest")
  msg := sprintf("Container %q uses the :latest tag — pin a version or digest", [c.name])
}

# Require image to come from the trusted ACR.
warn[msg] {
  input.kind == "Deployment"
  some i
  c := input.spec.template.spec.containers[i]
  not contains(c.image, "acrtelcodemo.azurecr.io/")
  msg := sprintf("Container %q image %q is not from the trusted ACR", [c.name, c.image])
}
