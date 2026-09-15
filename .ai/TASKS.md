# Current Work

## Active

- Planning update — record the registry (ECR removed), Cloudflare DNS, ingress, and account/region decisions. No implementation started; the user asked not to write code yet.

## Roadmap

Each phase is small and independently verifiable. AWS phases require explicit authorization and a plan before any apply.

### Phase 0 — Context adoption and foundation
- Adopt `.ai/` context from the approved brief.
- Create `.gitignore` and a real `README.md` overview.
- Create the directory skeleton (`infrastructure/`, `application/`, `gitops/`, `docs/`).
- Validation: repository structure review only (no build tooling yet).

### Phase 1 — Application, Docker, Helm (local, no AWS)
- Small API with `/` and `/health`; unit tests.
- Multi-stage `Dockerfile`.
- Helm chart with `readinessProbe`, `livenessProbe`, `requests`, `limits`, and `/health` health check.
- Validation: app tests, `docker build`, `helm lint`, `helm template`.

### Phase 2 — Terraform modules and root (no apply)
- `modules/vpc` per ADR-013: create-or-adopt VPC (`vpc_cidr` or `vpc_id`), configurable `public_subnet_cidrs`/`private_subnet_cidrs` + `azs`, supplied `internet_gateway_id`/`nat_gateway_id` with optional creation, and route tables always created/owned with associations and routes.
- `modules/eks`, `modules/iam` (no ECR module).
- `environments/dev` root with the mandatory tags.
- Decide/implement the OIDC role for GitHub Actions and the ALB controller identity.
- Validation: `terraform fmt -recursive`, `terraform validate`, `tflint`, Checkov; `plan` only with authorization.

### Phase 3 — Provision AWS (requires authorization + credits)
- Present plan, resources, and qualitative cost estimate first.
- `apply` VPC, EKS, IAM (registry is external; no ECR); configure `kubectl`.
- Validation: cluster reachable; `terraform output` values captured.

### Phase 4 — Platform add-ons (GitOps)
- Install Argo CD via Helm into `argocd`.
- Install AWS Load Balancer Controller via Helm with the chosen identity.
- Bootstrap App of Apps.
- Validation: pods healthy; controller registered.

### Phase 5 — Workloads dev/prod
- `gitops/environments/dev` and `prod`; `Application`/`ApplicationSet`.
- `dev`: automated `prune` + `selfHeal`; `prod`: PR-gated.
- ALB `Ingress` with `ingressClassName: alb` and `/health` check; Sync Waves for ordering.
- Cloudflare DNS record pointing to the ALB; optional ACM certificate for an HTTPS listener.
- Validation: both namespaces synced; the Cloudflare hostname resolves and serves `/health`.

### Phase 6 — CI/CD
- GitHub Actions: test, lint, Trivy, immutable-tag build, GHCR push (GITHUB_TOKEN), dev tag update, prod promotion PR.
- Validation: workflow run produces a new registry tag and a GitOps commit.

### Phase 7 — Demonstrations and evidence
- dev sync, ALB access, `/health`, drift + `selfHeal`, prod promotion via PR, rollback via `git revert`.
- Capture screenshots/GIFs.
- Validation: each demo reproduced and recorded.

### Phase 8 — Teardown and final documentation
- Run and verify `terraform destroy`; confirm no EKS, EC2, EBS, ALB, or Elastic IP remains.
- Finalize README with real commands, architecture, and an interview demo checklist.
- Validation: AWS account confirms zero billable lab resources.

## Open decisions (must resolve before the dependent phase)

1. Repository owner/GitHub org and the Cloudflare zone + record name — supplied by the author (never invented). AWS region (`us-east-1`) and account are known; the account id stays in private config, not versioned files.
2. Network egress path for private subnets without NAT (ADR-012). The VPC module shape is decided (ADR-013: create-or-adopt, configurable subnets, supplied IGW/NAT, always-create route tables); the remaining choice is public subnets vs private subnets + VPC endpoints. Needed before Phase 2.
3. Container registry: GHCR vs Docker Hub, and public vs private package (ADR-014). Needed before Phase 1/6.
4. Ingress implementation confirmed as AWS ALB vs Envoy (ADR-015). Needed before Phase 4/5.
5. ALB controller identity: EKS Pod Identity vs IRSA (ADR-011). Needed before Phase 2/4.
6. EKS version and node group size (smallest that runs Argo CD + controller). Needed before Phase 2.
7. Terraform state backend: local vs S3 + lock. Needed before Phase 3.
8. TLS: ACM certificate for the ALB vs HTTP-only (ADR-016). Needed before Phase 5.

## Blocked

- AWS-facing phases are blocked on explicit authorization and on the open decisions above.

## Completed

- Adopted `.ai/` context from the approved project brief (2026-09-15).
- Recorded the flexible VPC module requirement (ADR-013) during planning.
- Recorded registry/DNS/ingress decisions: ECR removed, GHCR proposed (ADR-014), ALB proposed (ADR-015), Cloudflare DNS (ADR-016); region `us-east-1`.
