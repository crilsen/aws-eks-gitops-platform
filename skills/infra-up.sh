#!/usr/bin/env bash
set -euo pipefail

# aws-eks-gitops-platform: Full infrastructure setup
# Creates VPC, EKS, IAM, OIDC, Argo CD, and bootstraps the App of Apps.

ENV="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TF_DIR="$ROOT_DIR/infrastructure/environments/$ENV"
REGION="us-east-1"
CLUSTER_NAME="aws-eks-gitops-platform"
USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null)
USER_NAME=$(echo "$USER_ARN" | cut -d'/' -f2)

echo "============================================"
echo " aws-eks-gitops-platform — infra-up ($ENV)"
echo "============================================"
echo ""

# --- Step 1: Terraform apply ---
echo "[1/7] Terraform apply..."
cd "$TF_DIR"
terraform init -input=false
terraform apply -input=false -auto-approve
cd "$ROOT_DIR"

# --- Step 2: kubeconfig ---
echo "[2/7] Updating kubeconfig..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

# --- Step 3: Access entry ---
echo "[3/7] Creating access entry..."
aws eks create-access-entry \
  --cluster-name "$CLUSTER_NAME" \
  --principal-arn "$USER_ARN" \
  --type STANDARD 2>/dev/null || true

aws eks associate-access-policy \
  --cluster-name "$CLUSTER_NAME" \
  --principal-arn "$USER_ARN" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster 2>/dev/null || true

# --- Step 4: Wait for nodes ---
echo "[4/7] Waiting for nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# --- Step 5: Argo CD install ---
echo "[5/7] Installing Argo CD..."
cd "$ROOT_DIR"
~/bin/helm upgrade --install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --version 10.9.1 \
  -f gitops/argocd/values.yaml 2>/dev/null || \
helm upgrade --install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --version 10.9.1 \
  -f gitops/argocd/values.yaml

# --- Step 6: Annotate SA for IRSA ---
echo "[6/7] Annotating ALB controller SA for IRSA..."
ROLE_ARN=$(cd "$TF_DIR" && terraform output -raw alb_controller_role_arn 2>/dev/null)
kubectl annotate sa -n kube-system aws-load-balancer-controller \
  eks.amazonaws.com/role-arn="$ROLE_ARN" --overwrite 2>/dev/null || true

# --- Step 7: Bootstrap App of Apps ---
echo "[7/7] Bootstrapping App of Apps..."
kubectl apply -f gitops/bootstrap/root-app.yaml

echo ""
echo "============================================"
echo " Done! Checking status..."
echo "============================================"
echo ""
kubectl get nodes -o wide
echo ""
kubectl get pods -A
echo ""
kubectl get applications -n argocd -o wide
echo ""
echo "Argo CD UI: kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo "Password:   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
