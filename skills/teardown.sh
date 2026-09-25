#!/usr/bin/env bash
set -euo pipefail

# aws-eks-gitops-platform: Tear down everything
# Destroys EKS cluster, VPC, IAM, and cleans up local state.

ENV="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TF_DIR="$ROOT_DIR/infrastructure/environments/$ENV"
CLUSTER_NAME="aws-eks-gitops-platform"

echo "============================================"
echo " aws-eks-gitops-platform — teardown ($ENV)"
echo "============================================"
echo ""
echo "This will destroy ALL AWS resources for the $ENV environment."
read -p "Are you sure? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

# --- 1. Collect evidence before destroy ---
echo "[1/6] Collecting evidence before destroy..."
"$SCRIPT_DIR/collect-evidence.sh" "$ENV" 2>/dev/null || true

# --- 2. Delete the root App and let ArgoCD cascade in reverse wave order ---
# All Applications carry resources-finalizer.argocd.argoproj.io, so deleting
# `root` removes workloads (wave 0) before the controller (wave -1).
# Ingress deletion makes the still-running controller delete the ALB.
echo "[2/7] Deleting ArgoCD root App (cascade: workloads before controller)..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "${REGION:-us-east-1}" >/dev/null 2>&1 || true
kubectl delete -f "$ROOT_DIR/gitops/bootstrap/root-app.yaml" --ignore-not-found --wait >/dev/null 2>&1 || true

echo "Waiting for the ALB to be deleted by the controller..."
VPC_ID=$(cd "$TF_DIR" && terraform output -raw vpc_id 2>/dev/null || echo "")
for i in $(seq 1 60); do
  if [ -z "$VPC_ID" ]; then break; fi
  ALBS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text 2>/dev/null)
  if [ -z "$ALBS" ] || [ "$ALBS" = "None" ]; then echo " ALB deleted."; break; fi
  sleep 10; echo -n "."
done

# --- 3. Delete node group (if exists) ---
echo "[3/7] Deleting node group (if exists)..."
aws eks delete-nodegroup \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "${CLUSTER_NAME}-default" 2>/dev/null || true

echo "Waiting for node group to be deleted..."
while aws eks describe-nodegroup \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "${CLUSTER_NAME}-default" \
  --query 'nodegroup.status' --output text 2>/dev/null | \
  grep -qE "DELETING|CREATING|UPDATING"; do
  sleep 10
  echo -n "."
done
echo " done"

# --- 3. Force unlock state (if locked) ---
echo "[4/7] Checking state lock..."
cd "$TF_DIR"
LOCK_FILE="s3://$(grep 'bucket' versions.tf | head -1 | awk -F'"' '{print $2}')/$(grep 'key' versions.tf | head -1 | awk -F'"' '{print $2}')"
if aws s3api head-object --bucket "$(echo $LOCK_FILE | cut -d'/' -f3)" --key "$(echo $LOCK_FILE | cut -d'/' -f4-)" >/dev/null 2>&1; then
  LOCK_ID=$(aws s3 cp "$LOCK_FILE" - 2>/dev/null | grep -o '"ID":"[^"]*"' | cut -d'"' -f4)
  if [ -n "$LOCK_ID" ]; then
    echo "Force-unlocking state ($LOCK_ID)..."
    echo "yes" | terraform force-unlock -force "$LOCK_ID" 2>/dev/null || true
  fi
fi
cd "$ROOT_DIR"

# --- 4. Terraform destroy ---
echo "[5/7] Terraform destroy..."
cd "$TF_DIR"
terraform destroy -input=false -auto-approve
cd "$ROOT_DIR"

# --- 5. Verify cleanup ---
echo "[6/7] Verifying cleanup..."
CLUSTER_EXISTS=$(aws eks list-clusters --query "clusters[?@\`==\`'$CLUSTER_NAME']" --output text 2>/dev/null)
if [ -n "$CLUSTER_EXISTS" ]; then
  echo "WARNING: Cluster still exists!"
else
  echo "Cluster deleted."
fi

VPC_EXISTS=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=aws-eks-gitops-platform" --query 'Vpcs[].VpcId' --output text 2>/dev/null)
if [ -n "$VPC_EXISTS" ]; then
  echo "WARNING: VPC still exists: $VPC_EXISTS"
else
  echo "VPC deleted."
fi

ORPHAN_ALBS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'k8s-')].LoadBalancerArn" --output text 2>/dev/null)
if [ -n "$ORPHAN_ALBS" ] && [ "$ORPHAN_ALBS" != "None" ]; then
  echo "WARNING: orphan ALB(s) left behind (delete manually): $ORPHAN_ALBS"
else
  echo "No orphan ALBs."
fi

# --- 6. Clean local state ---
echo "[7/7] Cleaning local state..."
rm -rf "$TF_DIR/.terraform" 2>/dev/null || true
kubectl config delete-context "arn:aws:eks:${REGION:-us-east-1}:$(aws sts get-caller-identity --query 'Account' --output text):cluster/$CLUSTER_NAME" 2>/dev/null || true

echo ""
echo "============================================"
echo " Teardown complete!"
echo " Evidence saved before destroy."
echo "============================================"
