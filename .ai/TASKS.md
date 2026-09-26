# Current Work

## Active

- Infra destroyed 2026-09-26 (61 resources, state empty, verified: no cluster/VPC/ALB/NAT; app was live end-to-end before teardown).
- Next (needs fresh `apply`): drift/selfHeal demo, prod promotion PR, rollback demo, screenshots/GIFs, final README.

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

### Phase 2 — Terraform modules and root (done, applied)
- `modules/vpc` per ADR-013, creating the VPC/IGW/NAT (`10.12.0.0/16`, `/24` subnets per ADR-019 as amended), always creating route tables (public -> IGW, private -> NAT).
- `modules/eks` (1.36, 2× `t3.small` nodes) and `modules/iam` (ALB controller via IRSA, ADR-026). No ECR module.
- `environments/dev` root with the mandatory tags and the S3 backend (ADR-017), plus the cluster OIDC provider and the ACM import.
- Validation: `terraform fmt -recursive`, `terraform validate`, `terraform plan` + `apply` (authorized); 64 managed resources in state.

### Phase 3 — Provision AWS (requires authorization + credits)
- Present plan, resources, and qualitative cost estimate first.
- `init` with the S3 backend, then `apply` EKS, IAM, subnets/route tables (registry is external; no ECR); configure `kubectl`.
- Validation: cluster reachable; `terraform output` values captured.

### Phase 4 — Platform add-ons (GitOps)
- Install Argo CD via Helm into `argocd`.
- Install AWS Load Balancer Controller via Helm with the chosen identity.
- Bootstrap App of Apps.
- Validation: pods healthy; controller registered.

### Phase 5 — Workloads dev/prd
- `gitops/environments/dev` and `prd`; `Application`/`ApplicationSet`.
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

Resolved: ALB controller identity (IRSA, ADR-026 superseding ADR-011), S3 bucket `cn-terraform-state-us-east-1` + S3 native lock with `dev`/`prd` folders (ADR-017), Cloudflare hostnames `app-dev.crilsen.com` (dev, live) and `app.crilsen.com` (prod, pending prod deploy) (ADR-016), EKS version 1.36 (ADR-018), application stack Python + FastAPI (ADR-020), subnet CIDRs `10.12.21.0/24` onward in created `10.12.0.0/16` (ADR-019 as amended), registry GHCR (ADR-014), 2× `t3.small` nodes (ADR-018 as amended).

## Blocked

- AWS apply/destroy (Phase 3+) remains blocked only on explicit authorization and a cost review.

## Completed

- Adopted `.ai/` context from the approved project brief (2026-09-15).
- Recorded the flexible VPC module requirement (ADR-013) during planning.
- Recorded registry/DNS/ingress decisions (ADR-014/015/016) and AWS decisions (ADR-012/017/018/019 as amended): S3 state, created VPC/IGW/NAT `10.12.0.0/16`, ALB + ACM import, Cloudflare `crilsen.com`, EKS 1.36 + 2× `t3.small` nodes, subnets `10.12.21.0/24` onward, region `us-east-1`.
- Implemented and validated `infrastructure/modules/vpc` (`terraform fmt`, `terraform validate`).
- Implemented Phase 1: FastAPI application (`/`, `/health`), tests, multi-stage Dockerfile (non-root), and Helm chart with probes/resources/optional ALB Ingress. Validated with pytest, `docker build`, container smoke test, `helm lint`, `helm template`.
- Decided the application stack (Python + FastAPI, ADR-020) and the ALB controller identity (IRSA via ADR-026, superseding ADR-011 Pod Identity after controller crashes).
- Created `infrastructure/environments/dev` (S3 backend `cn-terraform-state-us-east-1` key `aws-eks-gitops-platform/dev/terraform.tfstate`, created network, EKS 1.36 + OIDC provider, IAM role for the controller, ACM import). Validated with `terraform fmt`, `validate`, `plan`, and authorized `apply` runs.
- Implemented `infrastructure/modules/eks` (shared cluster 1.36, managed node group 2× `t3.small`, pod-identity-agent addon; vpc-cni/kube-proxy/coredns bootstrapped) and wired it into `environments/dev`. Decided environment isolation (ADR-022: one cluster, `dev`/`prd` namespaces).
- Implemented `infrastructure/modules/iam` (ALB controller IAM policy + IRSA role trusting the cluster OIDC provider) and wired it into `environments/dev`. Restricted the public API endpoint to specific CIDRs required via `terraform.tfvars` (validation rejects `0.0.0.0/0`). Deferred GitHub OIDC (ADR-023). Validated with `terraform fmt` and `terraform validate`.
- Implemented `gitops/` (Argo CD 10.9.1 values, App of Apps root, AWS Load Balancer Controller Application 3.5.0 with IRSA annotation, dev/prd workload Applications, environment values with ALB Ingress on `app-dev.crilsen.com`/`app.crilsen.com`). Validated YAML parsing and `helm lint`/`template` with the dev values. Live: root + controller `Synced`/`Healthy`, ALB active with the dedicated SG, `app-dev` `Synced`/`Degraded` on the GHCR 401.
- Implemented CI at the repository root: `.github/workflows/ci.yml` (pytest, docker build, Trivy scan, GHCR push with immutable SHA, GitOps dev tag update) and `.github/workflows/promote.yml` (manual PR to promote to prd). Registry chosen: GHCR (ADR-014). Validated with actionlint.
- Imported the user-supplied Let's Encrypt certificate (`*.crilsen.com`, valid to Dec 2026) into ACM via `aws_acm_certificate` in `environments/dev` (leaf/chain split, file-existence preconditions); the ALB discovers it by hostname, and the private key stays gitignored in `cert/` (ADR-024).
- Created one tagged, least-privilege SG per resource in `modules/eks` (ALB 80/443 in + app port out; nodes app port + 443 in; cluster 443/10250), all additive to the EKS-managed SG; ALB pinned via Terraform-rendered `alb-sg.yaml` overrides (ADR-025). Applied: nodes rolled with both SGs, ALB `k8s-dev-appawsek-c0aa531d7f` active with the dedicated SG.
- Fixed cross-subnet DNS: NACLs only allowed TCP, so UDP replies never crossed subnet boundaries. Added DNS UDP/TCP 53 (scoped to VPC CIDR) + UDP ephemeral rules; verified 4/4 node×DNS combinations. Relaxed ArgoCD repo-server probes for t3.small throttling.
- Blocker: GHCR package `aws-eks-gitops-platform` is private → kubelet gets 401. Flip to public in the package settings (ADR-014 already prescribes public).
- App live: package flipped to public by the owner; rebuilt the image multi-arch (`linux/amd64,linux/arm64` — local ARM build didn't match x86 nodes) and pushed; pod `Running`, ALB targets healthy, `/health` returns 200 via `app-dev.crilsen.com` end-to-end.
