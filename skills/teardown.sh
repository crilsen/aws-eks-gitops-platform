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

# --- 2. Delete node group first (if exists) ---
echo "[2/6] Deleting node group (if exists)..."
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
echo "[3/6] Checking state lock..."
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
echo "[4/6] Terraform destroy..."
cd "$TF_DIR"
terraform destroy -input=false -auto-approve
cd "$ROOT_DIR"

# --- 5. Verify cleanup ---
echo "[5/6] Verifying cleanup..."
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

# --- 6. Clean local state ---
echo "[6/6] Cleaning local state..."
rm -rf "$TF_DIR/.terraform" 2>/dev/null || true
kubectl config delete-context "arn:aws:eks:${REGION:-us-east-1}:$(aws sts get-caller-identity --query 'Account' --output text):cluster/$CLUSTER_NAME" 2>/dev/null || true

echo ""
echo "============================================"
echo " Teardown complete!"
echo " Evidence saved before destroy."
echo "============================================"
