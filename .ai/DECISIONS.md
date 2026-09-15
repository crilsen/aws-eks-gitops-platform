# Architectural Decisions

## ADR-001 — Bounded learnings buffer with promotion

Status: Accepted

Context:
The template recorded state (`TASKS.md`, `HANDOFF.md`) and durable choices (`DECISIONS.md`), but had no mechanism for an agent to retain reusable, non-obvious learnings across sessions and tools.

Decision:
Introduce `.ai/LEARNINGS.md` as a bounded, append-only buffer with a fixed entry format, promotion rules, and compaction at 40 active entries. Durable learnings are promoted to `CONVENTIONS.md`, `DECISIONS.md`, `TOOLS.md`, or `VALIDATION.md` and the entry is marked `promoted`.

Reasoning:
Keeps the normative files clean and evidence-based while giving agents an explicit, portable place to capture what they learned, avoiding rediscovery and drift between tools.

Consequences:
- Learnings are portable and versioned with the repository.
- The buffer can grow and must be compacted; promotion directs durable rules to their permanent home.
- Agents must follow `.ai/workflows/capture-learning.md` rather than writing ad-hoc notes.

## ADR-002 — Agent-independent context with thin adapters

Status: Accepted

Context:
Work must continue across different agents, models, providers, and machines, including when one provider's usage limit is reached. Tool-specific files and chat history are not portable.

Decision:
Keep `AGENTS.md` and `.ai/` as the only source of truth. Any tool-specific file is a thin adapter that routes to `AGENTS.md` and contains no project facts; adapter paths are catalogued in `.ai/ADAPTERS.md`. Handoff state is carried by the Resume block in `.ai/HANDOFF.md` and the protocol in `.ai/workflows/switch-agent.md`, and must be committed and pushed or explicitly listed as uncommitted.

Reasoning:
The repository is the only medium every agent can read. Keeping adapters thin prevents drift, and centralizing handoff in version-controlled files makes agents interchangeable.

Consequences:
- Context survives agent, model, provider, and machine changes.
- Agents with lower context windows or tighter limits can resume because `AGENTS.md` stays small and `.ai/` is read on demand.
- Uncommitted work can be lost on a machine switch unless it is committed, pushed, or listed in `HANDOFF.md`.

## ADR-003 — Rolling checkpoints with usage-limit thresholds

Status: Accepted

Context:
Provider usage can be exhausted mid-task. The agent cannot always read the exact remaining quota, and losing work at the limit defeats the portability goals.

Decision:
Adopt a rolling checkpoint: the Resume block in `.ai/HANDOFF.md` is kept current after every meaningful step. Define usage thresholds in `.ai/LIMITS.md` (warn at 70%, stop starting new work and finalize at 85%). Use reported usage when the tool exposes it, plus a self-imposed work-volume proxy otherwise.

Reasoning:
A continuously current handoff makes any interruption resumable, and explicit thresholds turn an abrupt limit into a planned handoff.

Consequences:
- Interruptions and provider switches become routine rather than lossy.
- Agents must commit or list work in progress and must not claim an unobserved quota.
- Tool-specific watchers (statusline, hook, plugin) are optional and stay thin; the policy remains portable.

## ADR-004 — Single monorepo with area-separated directories

Status: Accepted

Context:
The project must be one public repository to tell a coherent story and simplify review, yet infrastructure, application, and GitOps concerns should not be entangled.

Decision:
Use one monorepo with `infrastructure/`, `application/`, `gitops/`, and `docs/`, structured so any area can later be extracted into its own repository with low rework.

Reasoning:
Keeps the portfolio easy to consume while preserving clean boundaries between IaC, application, and delivery.

Consequences:
- Cross-area changes are visible in one PR.
- Directory boundaries must stay honest, or extraction becomes costly.

## ADR-005 — dev and prod as namespaces in one temporary cluster

Status: Accepted

Context:
Marketing a second cluster or account would double cost and time, which the US$ 100 budget does not justify.

Decision:
Run `dev` and `prod` as separate namespaces in a single temporary EKS cluster. `dev` is auto-synced; `prod` changes only through reviewed, manually synced Git changes.

Reasoning:
Demonstrates environment separation and promotion discipline at minimal cost.

Consequences:
- Weaker isolation than separate clusters/accounts; documented as a lab trade-off.
- One cluster means one blast radius and one teardown.

## ADR-006 — Cost guardrails exclude NAT and secondary managed services

Status: Accepted

Context:
The lab runs on limited credits and must not create surprise cost.

Decision:
No NAT Gateway, Route 53, domain, ACM, RDS, OpenSearch, ElastiCache, EKS Auto Mode, or AWS-managed Argo CD capabilities. Step EKS, EC2, EBS, ALB, and Elastic IP after the demo. Network egress without NAT must be solved with VPC endpoints or an equivalent documented approach.

Reasoning:
NAT and managed data services dominate cost; the learning goals are reachable without them.

Consequences:
- The network design must provide image/registry and needed API egress without NAT.
- The exact egress strategy is an open decision (see ADR-012).

## ADR-007 — GitHub OIDC instead of static AWS credentials in CI

Status: Accepted

Context:
CI must push to the container registry (see ADR-014) and update Git, and the brief forbids persistent access keys.

Decision:
Use GitHub Actions OIDC with a least-privilege IAM role assumed at run time; never store `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` as secrets.

Reasoning:
Short-lived, scoped credentials remove a classic long-lived-secret risk and are the expected practice for interviews.

Consequences:
- An OIDC provider and trust policy must be Terraform-managed.
- Workflows must request `id-token: write`.

## ADR-008 — Immutable commit-SHA image tags only

Status: Accepted

Context:
Mutable tags such as `latest` make deployments non-reproducible and rollback ambiguous.

Decision:
Tag every image with the immutable commit SHA and reference that exact tag in the GitOps directory; never deploy `latest`.

Reasoning:
Guarantees the deployed artifact is traceable and rollback by commit revert is meaningful.

Consequences:
- Every deploy requires a Git commit updating the tag.
- Rollback is a `git revert` of the tag change.

## ADR-009 — dev auto-sync, prod PR-gated

Status: Accepted

Context:
The brief requires an automatic GitOps loop for `dev` and a controlled, reviewable path to `prod`.

Decision:
`dev` uses `syncPolicy.automated` with `prune: true` and `selfHeal: true`. `prod` has no unrestricted automated sync; promotion happens through a pull request and a reviewed, manual sync.

Reasoning:
Demonstrates both continuous delivery and change control.

Consequences:
- Drift in `dev` is auto-corrected (used for the drift demo).
- `prod` requires human approval by design.

## ADR-010 — One temporary ALB via the AWS Load Balancer Controller, native DNS

Status: Superseded in part by ADR-016 (a Cloudflare-managed hostname is now used); the single-ALB and no-extra-LB decisions still hold.

Context:
Ingress must be demonstrable without owning a domain, and multiple ALBs would add cost.

Decision:
Create a Kubernetes `Ingress` with `ingressClassName: alb`; expose the app over HTTP through the ALB's native DNS name; use the `/health` endpoint as the target health check. No Route 53, custom domain, ACM, or extra ALBs. The ALB, a Kubernetes-created resource, is removed with the environment on teardown.

Reasoning:
Minimal, cost-aware way to prove ingress, and it exercises the controller's identity setup.

Consequences:
- Access is by the ALB DNS name only; no TLS in this lab.
- Teardown must confirm the ALB and its security groups are gone.

## ADR-011 — ALB controller identity: EKS Pod Identity

Status: Accepted

Context:
The brief allows IRSA or EKS Pod Identity for the AWS Load Balancer Controller. EKS Pod Identity is the current AWS-recommended mechanism and is simpler to operate.

Decision:
Use EKS Pod Identity for the AWS Load Balancer Controller. Terraform creates the Pod Identity association; the EKS Pod Identity agent runs on the nodes. IRSA is the fallback only if a concrete constraint rules Pod Identity out.

Reasoning:
Fewer moving parts than IRSA trust wiring and aligns with current AWS guidance.

Consequences:
- Requires the EKS Pod Identity agent on nodes and a Pod Identity association in Terraform.
- The EKS add-on/agent must be available for the chosen EKS version.

## ADR-012 — Adopt the existing network; reuse IGW and NAT for egress

Status: Accepted

Context:
The author supplies an existing VPC, an existing Internet Gateway, and an existing NAT Gateway in `us-east-1`. NAT creation is prohibited by ADR-006, but reusing an already-provisioned NAT is allowed and removes the egress problem that the ECR removal introduced (image registry and GitHub are internet destinations).

Decision:
Adopt the existing VPC/IGW/NAT (ids supplied privately, not versioned). The node group runs in private subnets and egresses through the reused NAT; public subnets host the ALB. The module still creates and owns all route tables (ADR-013) and creates the subnets from the agreed CIDR scheme (ADR-019).

Reasoning:
Reusing existing networking satisfies the no-new-NAT cost rule while keeping private nodes, image pulls, and GitOps sync functional.

Consequences:
- No NAT or IGW is created; both are inputs.
- Private-subnet egress depends on the reused NAT remaining available.
- If the NAT is removed, the no-egress scenario returns; document this dependency.

## ADR-013 — Flexible create-or-adopt VPC module

Status: Accepted

Context:
The lab may run in a fresh account or inside a pre-existing network, and must honor the no-new-NAT cost rule while still allowing network pieces (IGW, NAT) to be provided when they already exist. The author requires configurable subnet CIDRs and Terraform-owned route tables.

Decision:
The `infrastructure/modules/vpc` module must:
- toggle between creating a VPC (`vpc_cidr`) and adopting an existing one (`vpc_id`);
- create subnets from configurable CIDRs (`public_subnet_cidrs`, `private_subnet_cidrs`) and `azs`, in the new or adopted VPC;
- reuse a supplied `internet_gateway_id` or create an IGW;
- reuse a supplied `nat_gateway_id` or create NAT only when explicitly enabled (default: no new NAT);
- always create and own the route tables, subnet associations, and routes (to IGW and/or NAT when available).

Reasoning:
Adoption keeps the project usable in shared or existing accounts without rebuilding networking; always-managed route tables keep routing explicit and reproducible; optional IGW/NAT reuse preserves the no-new-NAT cost rule.

Consequences:
- Subnets are module-managed even when the VPC is adopted; existing subnets are not imported, so provided CIDRs must not overlap existing ones.
- Without a NAT or VPC endpoints, private subnets have no egress; ADR-012 still governs the final egress choice.
- Input validation is required (`create_vpc` vs `vpc_id`, CIDR/AZ alignment, NAT/IGW optionality).

## ADR-014 — Parameterizable container registry (GHCR default, Docker Hub supported)

Status: Accepted

Context:
The author decided ECR is not needed and asked for the registry to be parameterizable between GitHub (GHCR) and Docker Hub. The repository is public, which favors free public images and native CI authentication.

Decision:
Make the registry a parameter. The Helm chart exposes `image.registry`/`image.repository` and the CI derives the image path from a configurable value; the default is GHCR (`ghcr.io`), with Docker Hub supported as an alternative. Images always use immutable commit-SHA tags. ECR is removed from scope and from Terraform.

Reasoning:
GHCR needs no AWS credentials (uses the workflow `GITHUB_TOKEN`) and is free for public repos; parameterizing keeps Docker Hub viable without code changes.

Consequences:
- Terraform has no ECR module.
- CI needs no AWS OIDC for the image push (OIDC remains relevant only if CI runs AWS operations).
- If the chosen repository/package is private, an image pull secret is required; keep it public for the lab.
- The default registry value must be documented in the chart and workflow.

## ADR-015 — Ingress via AWS Load Balancer Controller and ALB

Status: Accepted

Context:
The author asked whether ingress should use Envoy or AWS. The project is an AWS-focused portfolio and already requires an ALB demonstration.

Decision:
Use the AWS Load Balancer Controller with a Kubernetes `Ingress` (`ingressClassName: alb`) and a single ALB. Do not run Envoy Gateway or ingress-nginx as the primary ingress.

Reasoning:
On EKS, an Envoy-based gateway still needs an AWS load balancer (NLB) via the controller or cloud provider, so it adds a data-plane hop, extra pods, and extra cost without reducing the AWS footprint. ALB gives native HTTP health checks (easy `/health` wiring) and a clean IAM/Pod Identity story. Envoy/Gateway API stays a documented future enhancement.

Consequences:
- One temporary ALB is created and destroyed with the environment.
- Cloudflare points its DNS record at the ALB.
- Gateway API/Envoy is out of scope for this lab.

## ADR-016 — DNS via Cloudflare with ACM TLS

Status: Accepted

Context:
The author will manage DNS in Cloudflare for the zone `crilsen.com`, replacing the earlier "no domain / no Route 53" scope, and wants TLS via ACM.

Decision:
Point a Cloudflare record in `crilsen.com` at the ALB. Use an ACM certificate (free, region `us-east-1`) for the ALB HTTPS listener, validated by a DNS CNAME added in Cloudflare. Route 53 is not used.

Reasoning:
Cloudflare is the author's DNS provider and adds no AWS cost; ACM keeps TLS free.

Consequences:
- The Cloudflare zone is `crilsen.com`; the record/subdomain name is still an open input (not invented).
- ACM DNS validation requires adding a CNAME to Cloudflare; document the exact records.
- ADR-010's single-ALB and no-extra-LB rules still apply.

## ADR-017 — Terraform state in S3

Status: Accepted

Context:
The author chose an S3 backend for Terraform state instead of local state.

Decision:
Use an S3 bucket in `us-east-1` with per-state keys for remote state (and a lock mechanism, e.g., S3 lockfile or DynamoDB, to be confirmed). The bucket name and any credentials are supplied privately and are not versioned.

Reasoning:
Remote state is durable, shareable, and enables locking and CI use.

Consequences:
- A bucket must exist before the first `init`; confirm its name.
- Account id and bucket name stay in private config/backend files, not in `.ai/`.
- Backend is configured per environment root.

## ADR-018 — EKS: latest version, single small managed node

Status: Accepted

Context:
The author wants the newest EKS version with a single node on the smallest viable instance, within cost limits.

Decision:
Use the latest supported EKS version and one managed node group with a single `t3.small` node (2 vCPU / 2 GiB), confirmed by the author as the practical minimum for Argo CD plus the AWS Load Balancer Controller. Document the size and cost.

Reasoning:
Keeps the lab minimal and current while remaining functional; free-tier `t3.micro` (~1 GiB) is too small.

Consequences:
- `t3.small` is not free-tier eligible (~US$ 0.0208/hour on-demand in `us-east-1`).
- The EKS control plane is the dominant cost (~US$ 0.10/hour); destroy promptly after the demo.
- Confirm the exact EKS version at plan time rather than assuming.

## ADR-019 — Subnet CIDR scheme (/24 inside 10.11.0.0/16)

Status: Accepted

Context:
The author specified a VPC block of `10.11.0.0/16`, `/24` subnets "starting at `10.21`", and confirmed the intended reading: `10.11.21.0/24` onward, inside the adopted VPC.

Decision:
Create `/24` subnets inside the adopted VPC starting at `10.11.21.0/24`. Two AZs are required (EKS needs at least two; the ALB needs two public subnets). Initial allocation:
- public: `10.11.21.0/24`, `10.11.22.0/24`
- private: `10.11.23.0/24`, `10.11.24.0/24`

CIDRs remain variables so the environment can override them.

Reasoning:
Keeps subnets inside the VPC block and leaves room to grow; satisfies EKS and ALB multi-AZ requirements.

Consequences:
- Must not overlap existing subnets in the adopted VPC; verify before apply.
- The values are defaults in the environment root, not hardcoded in the module.

## ADR-020 — Example application: Python + FastAPI

Status: Accepted

Context:
The brief asks for a small example API with `/` and `/health`; the language was undecided.

Decision:
Implement the API in Python with FastAPI served by uvicorn. Ship a multi-stage Dockerfile (non-root runtime) and a Helm chart with readiness/liveness probes on `/health`, plus `requests`/`limits`.

Reasoning:
FastAPI is small, quick to test, and produces a compact image suitable for a cost-limited single node; it is widely recognized in Cloud/DevOps portfolios.

Consequences:
- App dependencies are pinned in `requirements.txt`.
- Tests use the FastAPI test client; CI runs them before building the image.
- Image runs as a non-root user to satisfy the security baseline.

## ADR-021 — GitHub Actions workflows live at the repository root

Status: Accepted

Context:
The brief's sketch placed workflows under `application/.github/workflows/`, but GitHub Actions only reads workflows from the repository root `.github/workflows/`. Files elsewhere are never executed.

Decision:
Put workflows in the root `.github/workflows/`, scoped to the application path via `paths`/working directories. Keep `application/` for source, Dockerfile, and chart only.

Reasoning:
Root workflows are the only ones GitHub runs; this keeps the monorepo functional without duplicating pipelines.

Consequences:
- The directory layout deviates slightly from the brief's sketch, documented here.
- Workflows must set explicit paths/working directories for the application.

Use this ADR format for durable, meaningful decisions:

```text
## ADR-NNN - Title

Status: Proposed | Accepted | Superseded | Deprecated

Context:
...

Decision:
...

Reasoning:
...

Consequences:
...
```

Do not backfill invented history. Record decisions that are observed, expressly documented, or approved during future work.
