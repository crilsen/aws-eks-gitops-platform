# Validation

## Completion rule

Before completion, run all applicable project validations that are available and safe. Report each as **Validated**, **Partially validated**, or **Not validated**, with the reason for anything not run. Never claim validation that did not occur.

## Terraform (`infrastructure/`)

1. `terraform fmt -recursive`
2. `terraform validate` (per environment root)
3. `tflint --recursive`
4. `checkov -d infrastructure/`
5. `terraform plan` only with credentials/backend available and explicit authorization.

## Kubernetes / Helm (`gitops/`, `application/helm`)

1. `helm lint application/helm`
2. `helm template application/helm` and diff against expected manifests.
3. Validate YAML under `gitops/`.
4. `kubectl diff`/client dry-run only against an authorized cluster.

## Application (`application/`)

1. Run the app test suite.
2. Lint/format checks for the app language.
3. `docker build` (no `push` without authorization).

## CI (GitHub Actions)

1. Confirm workflows use OIDC (`id-token: write`) and no static AWS credentials.
2. Confirm Trivy scan and immutable SHA image tag.

## Security

1. `checkov` on Terraform.
2. `trivy config` / `trivy image` as applicable.
3. Secret scan: confirm no credentials, tokens, or state files are tracked.

## Per-phase expectation

Exact commands become concrete as each phase lands. No project-specific validation has been executed yet; the repository contains no implementation to validate.
