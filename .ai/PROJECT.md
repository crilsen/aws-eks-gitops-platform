# Project

## Identity

- **Name:** aws-eks-gitops-platform
- **Objective:** Public portfolio project demonstrating, in practice, Platform Engineering, GitOps, Amazon EKS, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and AWS cost control.
- **Audience:** Technical interviews for Cloud Engineer, DevOps Engineer, SRE, and Cloud Solutions Architect roles.
- **Author:** Cristiano (senior Cloud/DevOps engineer; AWS, EKS, Terraform, security, networking, observability, multi-account).
- **Primary technologies:** Terraform, AWS (VPC, EKS, IAM, ALB via the AWS Load Balancer Controller), Kubernetes, Helm, Argo CD, GitHub Actions, Docker, Trivy, tflint, Checkov, Cloudflare DNS.
- **Repository model:** single public monorepo (`aws-eks-gitops-platform`) with responsibilities split by directory so each area can be extracted later with low effort.

## Scope (approved)

- Terraform-managed AWS infrastructure.
- Amazon EKS for the platform and workloads.
- Container registry for application images: **ECR removed**; GHCR (proposed) or Docker Hub to be confirmed.
- Argo CD open source installed on the cluster via Helm.
- AWS Load Balancer Controller installed via Helm.
- DNS via Cloudflare; ingress via AWS Load Balancer Controller + ALB (proposed, pending confirmation of the Envoy question).
- Small example API application with `/` and `/health`.
- Dockerfile and Helm chart for the application.
- `dev` and `prod` environments, initially separated by namespaces in one cluster.
- GitHub Actions for CI.
- GitOps flow: pipeline validates and pushes the image to the registry, then updates the image tag in the GitOps directory; Argo CD detects the change and deploys.
- Argo CD auto-sync with `prune` and `selfHeal` for `dev`.
- Promotion to `prod` via pull request and manual Git approval.
- Kubernetes `Ingress` using `ingressClassName: alb`.
- Public ALB reached by the Cloudflare DNS record (amends the earlier "no domain" scope).
- Drift demonstration: manual cluster change is reverted by Argo CD.
- Rollback documented by reverting a commit.
- Complete README: architecture, prerequisites, technical decisions, security, cost, execution, demonstrations, and teardown.

## Cost constraints (mandatory)

- Only US$ 100 in AWS credits is available; avoid accidental cost.
- One temporary EKS cluster only.
- No NAT Gateway.
- No Route 53 (DNS is Cloudflare), RDS, OpenSearch, ElastiCache, or other expensive managed services. ACM is allowed (free) if needed for ALB HTTPS.
- No EKS Auto Mode.
- No AWS-managed EKS Capabilities for Argo CD.
- Only one temporary ALB to demonstrate Ingress.
- Smallest viable node group that still runs Argo CD and the ALB controller.
- Leave no EKS, EC2, EBS, ALB, or Elastic IP running after the demo.
- Include and test the `terraform destroy` flow.
- Before any `terraform apply`, present the plan, the resources to be created, and a qualitative cost estimate.
- Never run `terraform apply`, create AWS resources, or consume credits without explicit authorization.

## Status

**Em desenvolvimento / work in progress — not functional.** Context adopted from an approved project brief (2026-09-15). No application, infrastructure, or GitOps artifacts exist yet. AWS region is `us-east-1`; the AWS account id is known to the author but must stay out of versioned context and be supplied privately. Repository owner is not invented. Open decisions are tracked in `TASKS.md`.
