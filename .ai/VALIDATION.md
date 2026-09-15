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

Run in the same base image as the Dockerfile (local Python may differ):

1. Tests: `docker run --rm -v "$PWD/application:/app" -w /app python:3.12-slim sh -c "pip install -q -r requirements-dev.txt && python -m pytest"`.
2. `docker build -t aws-eks-gitops-platform:test application/`.
3. Smoke test: run the image, `curl localhost:8000/` and `curl localhost:8000/health`.
4. Do not `docker push` without authorization.

## Helm chart (`application/helm`)

Helm is not installed locally; use the container:

1. `docker run --rm -v "$PWD:/apps" -w /apps alpine/helm:3.16.3 lint application/helm`.
2. `docker run --rm -v "$PWD:/apps" -w /apps alpine/helm:3.16.3 template app application/helm --set ingress.enabled=true --set 'ingress.hosts[0].host=app.crilsen.com'`.

## CI (GitHub Actions)

1. Confirm workflows use OIDC (`id-token: write`) and no static AWS credentials.
2. Confirm Trivy scan and immutable SHA image tag.

## Security

1. `checkov` on Terraform.
2. `trivy config` / `trivy image` as applicable.
3. Secret scan: confirm no credentials, tokens, or state files are tracked.

## Per-phase expectation

Exact commands become concrete as each phase lands. Validated so far: `modules/vpc` (`terraform fmt`, `terraform validate`) and the application (`pytest`, `docker build`, container smoke test, `helm lint`, `helm template`). `tflint`, `checkov`, and `trivy` are not installed.
