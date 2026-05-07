## What changed

<!-- One-line summary -->

## Why

<!-- Link to issue / CVE / change ticket -->

## Validation
- [ ] `helm lint` passes
- [ ] `helm template … | kubeconform` passes
- [ ] CodeQL clean
- [ ] Trivy: no new CRITICAL/HIGH (or justified in comment)
- [ ] No SUPI / IMSI / K / OPc in diff
- [ ] Subchart bumps include CVE references

## Risk & rollback
<!-- Argo CD will reconcile to the previous tag on `git revert` of the merge commit -->
