#!/bin/bash
set -e

START_TIME=$(date +%s)

# === Pre-check for existing users ===
USER_DIR="./break/users"
EXISTING_USERS=$(find "$USER_DIR" -mindepth 1 -maxdepth 1 -type d ! -name "sample" -exec basename {} \;)

if [ -n "$EXISTING_USERS" ]; then
  echo "⚠️  There are users defined:"
  echo "$EXISTING_USERS"
  echo ""
  read -p "❓ Would you like to delete them first? (yes/no): " CONFIRM
  if [ "$CONFIRM" == "yes" ]; then
    for USER_ID in $EXISTING_USERS; do
      echo "🧨 Running DELETE_USER.sh for $USER_ID..."
      echo -e "$USER_ID\nyes" | ./DELETE_USER.sh
    done
  else
    echo "⏭️  Skipping user deletion."
  fi
fi

# === Global Config ===
AWS_REGION="CHANGE_ME"
AWS_ACCOUNT_ID="CHANGE_ME"
CLUSTER_NAME="break-cluster"
export AWS_PAGER=""

# === break-in Config ===
BREAKIN_ECR_REPO="break-in"
BREAKIN_ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BREAKIN_ECR_REPO"
BREAKIN_ECR_IMAGE="$BREAKIN_ECR_URI:latest"

COMMON_DIR="./break/common"

# === break-out Config ===
BREAKOUT_ECR_REPO="break-out"
BREAKOUT_ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BREAKOUT_ECR_REPO"
BREAKOUT_ECR_IMAGE="$BREAKOUT_ECR_URI:latest"

# === Step 1: Destroy Terraform Infrastructure ===
echo "💣 Destroying common infrastructure..."
cd "$COMMON_DIR"
terraform destroy -auto-approve
cd - > /dev/null

# === Done ===
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))
echo "✅ Undeploy complete in ${MINUTES}m ${SECONDS}s"

