# Evidence

Current live state (verified 2026-09-25; historical logs below are from earlier runs).

## Live status

- Cluster `aws-eks-gitops-platform` (EKS 1.36): ACTIVE, 2× `t3.small` nodes Ready.
- ArgoCD: root `Synced`/`Healthy`, `aws-load-balancer-controller` `Synced`/`Healthy`.
- ALB `k8s-dev-appawsek-c0aa531d7f` active with the dedicated SG; serves `app-dev.crilsen.com` (HTTP 301 → HTTPS; HTTPS 503 until the app image pulls).
- `app-dev`: `Synced`/`Degraded` — pod `ImagePullBackOff` (GHCR package is private → kubelet 401; flip to public in package settings).
- `app-prd`: `OutOfSync`/`Missing` (manual, PR-gated — expected).
- Terraform state: 64 managed resources.

## Historical logs

- `01-terraform-plan.txt` — earlier plan (28 add / 3 change).
- `02-terraform-apply.txt` — earlier apply (59 resources at the time).
- `03-cluster-status.txt` — earlier cluster snapshot.
- `05-argocd-status.txt` — earlier ArgoCD snapshot.
- `09-terraform-destroy.txt` — earlier destroy run (kept as teardown evidence pattern).

## Still to collect

- `/health` 200 via `app-dev.crilsen.com` (after GHCR flip).
- Drift/selfHeal demo, prod promotion PR, rollback demo, screenshots/GIFs.
- Final `terraform destroy` verification.
