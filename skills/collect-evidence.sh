#!/usr/bin/env bash
set -euo pipefail

# aws-eks-gitops-platform: Collect evidence for portfolio
# Captures cluster status, nodes, pods, apps, ingress, and saves to evidence/.

ENV="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TF_DIR="$ROOT_DIR/infrastructure/environments/$ENV"
CLUSTER_NAME="aws-eks-gitops-platform"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
EVIDENCE_DIR="$ROOT_DIR/evidence/$TIMESTAMP"
mkdir -p "$EVIDENCE_DIR"

echo "============================================"
echo " aws-eks-gitops-platform — collect-evidence"
echo " Output: $EVIDENCE_DIR"
echo "============================================"
echo ""

# --- 1. Terraform state ---
echo "[1/6] Terraform state..."
cd "$TF_DIR"
terraform state list > "$EVIDENCE_DIR/terraform-state.txt" 2>&1
terraform plan -input=false -no-color > "$EVIDENCE_DIR/terraform-plan.txt" 2>&1 || true
cd "$ROOT_DIR"

# --- 2. Cluster ---
echo "[2/6] Cluster status..."
aws eks describe-cluster --name "$CLUSTER_NAME" \
  --query 'cluster.{name:name,version:version,status:status,endpoint:endpoint,createdAt:createdAt}' \
  --output table > "$EVIDENCE_DIR/cluster.txt" 2>&1

# --- 3. Nodes ---
echo "[3/6] Nodes..."
kubectl get nodes -o wide > "$EVIDENCE_DIR/nodes.txt" 2>&1

# --- 4. Pods ---
echo "[4/6] Pods..."
kubectl get pods -A -o wide > "$EVIDENCE_DIR/pods.txt" 2>&1

# --- 5. ArgoCD apps ---
echo "[5/6] ArgoCD applications..."
kubectl get applications -n argocd -o wide > "$EVIDENCE_DIR/argocd-apps.txt" 2>&1

# --- 6. Ingress ---
echo "[6/6] Ingress..."
kubectl get ingress -A -o wide > "$EVIDENCE_DIR/ingress.txt" 2>&1

# --- Summary ---
echo ""
echo "============================================"
echo " Evidence collected!"
echo "============================================"
echo ""
echo "Files:"
ls -la "$EVIDENCE_DIR/"
echo ""
echo "Quick status:"
echo "  Cluster: $(aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.status' --output text 2>/dev/null)"
echo "  Nodes:   $(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')"
echo "  Pods:    $(kubectl get pods -A --no-headers 2>/dev/null | grep -c Running 2>/dev/null || echo 0) running"
echo "  Apps:    $(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l | tr -d ' ')"
