# aws-eks-gitops-platform

> **Status: Work in progress.**
> Built in phases. So far: the VPC Terraform module and the Phase 1 application (FastAPI API with `/` and `/health`, Dockerfile, Helm chart). Nothing has been provisioned on AWS yet; the project is not yet functional end to end.

Public portfolio project demonstrating **Platform Engineering, GitOps, Amazon EKS, Terraform, Kubernetes, Helm, Argo CD, CI/CD, security, and AWS cost control**.

## What this project will demonstrate

- AWS infrastructure as code with Terraform (VPC, EKS, ECR, IAM).
- Amazon EKS running a small workload in `dev` and `prod` namespaces.
- Argo CD and the AWS Load Balancer Controller installed via Helm.
- A GitOps loop: GitHub Actions builds and pushes an immutable image tag to ECR, updates the GitOps directory, and Argo CD reconciles the cluster.
- `dev` auto-sync (`prune` + `selfHeal`); `prod` promoted by pull request.
- Drift correction and rollback by reverting a commit.
- Ingress exposed through a temporary public ALB DNS name (no domain, no Route 53).

## Planned structure

```text
infrastructure/   Terraform modules and the dev environment root
application/      Example API (/, /health), Dockerfile, Helm chart, CI
gitops/           Argo CD, bootstrap (App of Apps), applications, environments
docs/             Supporting documentation
```

## Cost and safety

The lab runs on limited credits. No NAT Gateway, Route 53, ACM, EKS Auto Mode, or AWS-managed Argo CD. All resources are temporary and torn down with `terraform destroy`. No AWS resource is created without explicit authorization.

## Getting started

Prerequisites: Terraform, AWS CLI, `kubectl`, Helm, Docker, and AWS credentials with a lab account.

Full setup, architecture, decisions, and demonstration commands will be documented here as the phases complete.

## Documentation

- Agent/project context: `AGENTS.md` and `.ai/` (project, architecture, conventions, decisions, tasks, handoff).
