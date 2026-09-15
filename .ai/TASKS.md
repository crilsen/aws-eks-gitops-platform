# Current Work

## Active

- Phase 1 complete — FastAPI app (`/`, `/health`), tests, multi-stage Dockerfile, and Helm chart implemented; validated with pytest, `docker build`, a container smoke test, `helm lint`, and `helm template`.
- Phase 2 in progress — `infrastructure/modules/vpc` implemented and validated; `environments/dev` root and `modules/eks`/`modules/iam` pending. CI (Phase 6) not started.

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
- `modules/vpc` per ADR-013, adopting the existing VPC/IGW/NAT (ids supplied privately), creating `/24` subnets per the agreed scheme, and always creating route tables (public -> IGW, private -> NAT).
- `modules/eks` (latest version, 1 small node) and `modules/iam` (ALB controller + OIDC). No ECR module.
- `environments/dev` root with the mandatory tags and the S3 backend (ADR-017).
- Decide/implement the OIDC role for GitHub Actions and the ALB controller identity.
- Validation: `terraform fmt -recursive`, `terraform validate`, `tflint`, Checkov; `plan` only with authorization.

### Phase 3 — Provision AWS (requires authorization + credits)
- Present plan, resources, and qualitative cost estimate first.
- `init` with the S3 backend, then `apply` EKS, IAM, subnets/route tables (registry is external; no ECR); configure `kubectl`.
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

1. **ALB controller identity (ADR-011) — blocking Phase 2/4.** Pod Identity vs IRSA.
2. **S3 bucket name + lock mechanism (ADR-017) — blocking Phase 3.**
3. **Cloudflare record name** (zone is `crilsen.com`) — blocking Phase 5.
4. **Exact EKS version** — confirm at plan time (use the latest supported).
5. **Application language/framework** for the example API — blocking Phase 1.

Resolved: subnet CIDRs (ADR-019), registry (ADR-014, parameterizable GHCR/Docker Hub), node instance type (ADR-018, `t3.small`).

## Blocked

- AWS apply phases are blocked on explicit authorization and on the open decisions above.
- Phase 1 is blocked on the application language/framework choice.

## Completed

- Adopted `.ai/` context from the approved project brief (2026-09-15).
- Recorded the flexible VPC module requirement (ADR-013) during planning.
- Recorded registry/DNS/ingress decisions (ADR-014/015/016) and AWS decisions (ADR-012/017/018/019): S3 state, adopt VPC/IGW/NAT, ALB + ACM, Cloudflare `crilsen.com`, EKS latest + 1 `t3.small` node, subnets `10.11.21.0/24` onward, region `us-east-1`.
- Implemented and validated `infrastructure/modules/vpc` (`terraform fmt`, `terraform validate`).
- Implemented Phase 1: FastAPI application (`/`, `/health`), tests, multi-stage Dockerfile (non-root), and Helm chart with probes/resources/optional ALB Ingress. Validated with pytest, `docker build`, container smoke test, `helm lint`, `helm template`.
- Decided the application stack (Python + FastAPI, ADR-020) and the ALB controller identity (EKS Pod Identity, ADR-011).
