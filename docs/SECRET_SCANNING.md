# Custom secret-scanning patterns for telco workloads

GHAS lets you add organisation- or repo-level custom patterns. The following
four are non-negotiable for any operator working with 3GPP credentials.

| Name | Description | Regex |
|------|-------------|-------|
| Telco IMSI | 3GPP IMSI (International Mobile Subscriber Identity) — 15 digits | `(?<![0-9])[0-9]{15}(?![0-9])` |
| Telco SUPI (NAI) | 5G Subscription Permanent Identifier in NAI form | `imsi-[0-9]{15}` |
| Telco K (auth key) | UICC/USIM K — 128-bit hex secret | `(?i)\b[0-9A-F]{32}\b` |
| Telco OPc | Operator Variant Algorithm Configuration field | `(?i)\bopc[:= ]+[0-9A-F]{32}\b` |

## How to add them

1. Go to `https://github.com/chapi-dev/telco-devsecops-demo/settings/security_analysis`.
2. Under **Secret scanning → Custom patterns**, click **New pattern**.
3. Paste the regex above as `Secret format`.
4. Tick **Push protection** so violations block at `git push`.
5. Save.

For org-wide rollout, add the same patterns under
**Organization settings → Code security and analysis → Custom patterns**.

## Why push protection matters

When push protection is enabled, a developer who accidentally commits an IMSI
list (e.g., a CSV pulled from a HSS export) will see GitHub block the push
*before* the data ever reaches the server. This is the only place in the
SDLC where prevention beats remediation: once a credential is on a remote, it
must be revoked, even if you immediately delete the commit.

## False positives

The K / OPc regex (`[0-9A-F]{32}`) overlaps with MD5 hashes and arbitrary
hex blobs. Two mitigations:

1. Add an `allowlist` for known-safe fixtures (e.g. `tests/fixtures/`).
2. Tighten the regex with anchoring keywords:
   ```
   (?i)\b(K|Ki)\s*[:=]\s*[0-9A-F]{32}\b
   ```

## In CI

Push protection is server-side. To also fail PRs that *check in* a secret,
the reusable security workflow (`security-reusable.yml`) runs Trivy and
Checkov, and you can add `gitleaks` if you want a second line of defence.
