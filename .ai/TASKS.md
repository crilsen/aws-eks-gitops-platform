# Current Work

## Active

- Phase 1 complete — FastAPI app (`/`, `/health`), tests, multi-stage Dockerfile, and Helm chart implemented; validated with pytest, `docker build`, a container smoke test, `helm lint`, and `helm template`.
- Phase 2 in progress — `modules/vpc`, `environments/dev` (S3 backend + adopted network), and `modules/eks` (shared cluster 1.36, 1× `t3.small`, managed add-ons) implemented and validated. `modules/iam` (ALB controller Pod Identity + GitHub OIDC) and `environments/prd` pending. CI (Phase 6) not started.

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

- None blocking. All previously open inputs are resolved (see below).

Resolved: ALB controller identity (ADR-011, EKS Pod Identity), S3 bucket `cn-terraform-state-us-east-1` + S3 native lock with `dev`/`prd` folders (ADR-017), Cloudflare hostnames `app-dev.crilsen.com` (dev) and `app.crilsen.com` (prod) (ADR-016), EKS version 1.36 (ADR-018), application stack Python + FastAPI (ADR-020), subnet CIDRs (ADR-019), registry (ADR-014), node `t3.small` (ADR-018).

## Blocked

- AWS apply/destroy (Phase 3+) remains blocked only on explicit authorization and a cost review.

## Completed

- Adopted `.ai/` context from the approved project brief (2026-09-15).
- Recorded the flexible VPC module requirement (ADR-013) during planning.
- Recorded registry/DNS/ingress decisions (ADR-014/015/016) and AWS decisions (ADR-012/017/018/019): S3 state, adopt VPC/IGW/NAT, ALB + ACM, Cloudflare `crilsen.com`, EKS 1.36 + 1 `t3.small` node, subnets `10.11.21.0/24` onward, region `us-east-1`.
- Implemented and validated `infrastructure/modules/vpc` (`terraform fmt`, `terraform validate`).
- Implemented Phase 1: FastAPI application (`/`, `/health`), tests, multi-stage Dockerfile (non-root), and Helm chart with probes/resources/optional ALB Ingress. Validated with pytest, `docker build`, container smoke test, `helm lint`, `helm template`.
- Decided the application stack (Python + FastAPI, ADR-020) and the ALB controller identity (EKS Pod Identity, ADR-011).
- Created `infrastructure/environments/dev` (S3 backend `cn-terraform-state-us-east-1` key `aws-eks-gitops-platform/dev/terraform.tfstate`, adopted network, subnet CIDRs). Validated with `terraform fmt` and `terraform validate`.
- Implemented `infrastructure/modules/eks` (shared cluster 1.36, managed node group 1× `t3.small`, core add-ons + pod identity agent) and wired it into `environments/dev`. Decided environment isolation (ADR-022: one cluster, `dev`/`prd` namespaces). Validated with `terraform fmt` and `terraform validate`.
