=== Evidence Summary ===

## 01-terraform-plan.txt
- 28 resources to add, 3 to change, 0 to destroy

## 02-terraform-apply.txt
- 59 resources created successfully

## 03-cluster-status.txt
- EKS cluster ACTIVE, version 1.36
- 1 node Ready (t3.small)
- All kube-system pods Running

## 05-argocd-status.txt
- Argo CD installed (chart 10.9.1)
- App of Apps root: Synced
- app-dev: OutOfSync (image not in GHCR)
- app-prd: OutOfSync
- aws-load-balancer-controller: Healthy but CrashLoopBackOff

## 09-terraform-destroy.txt
- Not yet collected

## Issues Found
1. GHCR package not public or image 0.1.0 not pushed
2. ALB controller CrashLoopBackOff (IAM or security group issue)
3. App pod ImagePullBackOff (depends on GHCR)

## Next Steps
1. Push image to GHCR (run CI)
2. Fix ALB controller permissions
3. Collect remaining evidence (drift, promotion, rollback, destroy)
