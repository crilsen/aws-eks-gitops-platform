# Tools

## Current availability

Project tooling is expected but not yet verified as installed on this machine: `terraform`, `tflint`, `checkov`, `trivy`, `aws`, `kubectl`, `helm`, `docker`, and `git`. Verify presence before relying on a check. AWS credentials, region, and account id are **Unknown / not determined from repository** and must be supplied by the author. Never store secrets in this file.

## Allowed without additional authorization

- Read and search repository files.
- Make scoped task-related edits.
- Run formatters, linters, tests, syntax checks, and validation commands listed in `VALIDATION.md` when the tooling exists.
- Run read-only commands and safe dry runs (`terraform fmt`, `validate`, `helm lint`, `helm template`, `docker build`).
- Update this portable context.

## Requires explicit authorization

- `terraform apply`, `terraform destroy`, `tofu apply`, `tofu destroy`.
- `kubectl apply`/`delete` against a real cluster and `helm install`/`upgrade` against real environments.
- Creating AWS resources, pushing images to a registry, or any action that consumes credits or mutates external systems.
- Secret changes, destructive state operations, or irreversible changes.

## Project tooling and impact

| Technology | Usually safe | Restricted |
| --- | --- | --- |
| Terraform | `fmt -recursive`, `validate`, `plan` (with creds, if authorized) | `apply`, `destroy` |
| tflint / Checkov | run against `infrastructure/` | — |
| Kubernetes | `get`, `describe`, `diff`, client dry-run | real-cluster apply/delete |
| Helm | `lint`, `template` | install/upgrade on real clusters |
| Trivy | `trivy image` scan, `trivy config` | — |
| Docker | `build` | `push` (publishes images / registry writes) |
| AWS CLI | `sts get-caller-identity`, read-only describes | any create/modify/delete |

Before running a command, confirm it is appropriate for the repository and does not require unavailable credentials or mutate external systems.
