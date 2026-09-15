# GitOps

Argo CD definitions for the platform and workloads. `dev` and `prd` are namespaces in one shared cluster (ADR-022).

## Layout

```text
gitops/
├── argocd/values.yaml        # Argo CD Helm values (bootstrap install)
├── bootstrap/root-app.yaml   # App of Apps root
├── applications/
│   ├── platform/             # platform add-ons (AWS Load Balancer Controller)
│   └── workloads/            # app-dev and app-prd Applications
└── environments/
    ├── dev/values.yaml       # dev chart values (image tag updated by CI)
    └── prd/values.yaml       # prd chart values (updated by promotion PR)
```

## Bootstrap

```sh
# 1. Install Argo CD
helm repo add argo https://argoproj.github.io/argo-helm && helm repo update
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace \
  --version 10.9.1 -f gitops/argocd/values.yaml

# 2. Apply the App of Apps
kubectl apply -f gitops/bootstrap/root-app.yaml

# 3. Access the UI (not exposed through the ALB)
kubectl -n argocd port-forward svc/argocd-server 8080:443
# initial admin password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Sync policy

- `app-dev`: `automated` with `prune` and `selfHeal` (drives the drift demonstration).
- `app-prd`: no automated sync; changes are promoted by a reviewed PR and a manual sync.

Child Applications use sync waves so platform (`-1`) is reconciled before workloads (`0`).

## Image flow

1. CI builds and pushes `ghcr.io/crilsen/aws-eks-gitops-platform:<commit-sha>`.
2. CI updates `image.tag` in `gitops/environments/dev/values.yaml`.
3. Argo CD reconciles `app-dev` and deploys the new tag.

`prod` promotion updates `gitops/environments/prd/values.yaml` through a pull request.

## Drift and rollback

- Drift: change a resource in the cluster; `app-dev` self-heals back to Git.
- Rollback: `git revert` the tag change in the environment values file; Argo CD re-syncs.

## Notes

- Branch: `dev` for now (`targetRevision: dev`); switch to `main` once promotion is established.
- TLS: the ALB discovers the ACM certificate for the ingress host; no certificate ARN is committed.
