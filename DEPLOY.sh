#!/bin/bash
set -e

START_TIME=$(date +%s)

# === Global Config ===
AWS_REGION="CHANGE_ME"           # <== CHANGE TO YOUR AWS REGION
AWS_ACCOUNT_ID="CHANGE_ME"       # <== CHANGE TO YOUR ACCOUNT ID NUMBER
CLUSTER_NAME="break-cluster"
SUBNET_ID="subnet-CHANGE_ME"     # < == CHANGE TO YOUR SUBNET ID NUMBER
export AWS_PAGER=""

# === break-in Config ===
BREAKIN_IMAGE_NAME="break-in"
BREAKIN_TAG="latest"
BREAKIN_ECR_REPO="break-in"
BREAKIN_ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BREAKIN_ECR_REPO"
BREAKIN_ECR_IMAGE="$BREAKIN_ECR_URI:$BREAKIN_TAG"

COMMON_DIR="./break/common"

# === break-out Config ===
BREAKOUT_IMAGE_NAME="break-out"
BREAKOUT_TAG="latest"
BREAKOUT_ECR_REPO="break-out"
BREAKOUT_ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BREAKOUT_ECR_REPO"
BREAKOUT_ECR_IMAGE="$BREAKOUT_ECR_URI:$BREAKOUT_TAG"

# === Step 1: Apply Common Infrastructure (Terraform) ===
echo "🔧 Applying common infrastructure..."
cd "$COMMON_DIR"
terraform init
terraform apply -auto-approve

ECR_IMAGE_URL_BREAK_IN=$(terraform output -raw ecr_repository_url_break_in)
ECR_IMAGE_URL_BREAK_OUT=$(terraform output -raw ecr_repository_url_break_out)
CLUSTER_ARN=$(terraform output -raw ecs_cluster_arn)
EXEC_ROLE_ARN=$(terraform output -raw execution_role_arn)
INVOKE_ROLE_ARN=$(terraform output -raw invoke_role_arn)
cd - > /dev/null

# === Step 2: Build Docker Image (break-in) ===
echo "🐳 Building Docker image (break-in)..."
docker build -t "$BREAKIN_IMAGE_NAME:$BREAKIN_TAG" -f Dockerfile.break-in .

# === Step 3: Authenticate to ECR ===
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# === Step 4: Build Docker Image (break-out) ===
echo "🐳 Building Docker image (break-out)..."
docker build -t "$BREAKOUT_IMAGE_NAME:$BREAKOUT_TAG" -f Dockerfile.break-out .

# === Step 5: Tag & Push Docker Image (break-in) ===
echo "🏷️ Tagging and pushing image (break-in)..."
docker tag "$BREAKIN_IMAGE_NAME:$BREAKIN_TAG" "$BREAKIN_ECR_IMAGE"
docker push "$BREAKIN_ECR_IMAGE"

# === Step 6: Tag & Push Docker Image (break-out) ===
echo "🏷️ Tagging and pushing image (break-out)..."
docker tag "$BREAKOUT_IMAGE_NAME:$BREAKOUT_TAG" "$BREAKOUT_ECR_IMAGE"
docker push "$BREAKOUT_ECR_IMAGE"

# === Step 8: Clean up local Docker images ===
echo "🗑️ Removing local Docker images..."
docker rmi -f "$BREAKIN_ECR_IMAGE" || true
docker rmi -f "$BREAKIN_IMAGE_NAME:$BREAKIN_TAG" || true
docker rmi -f "$BREAKOUT_ECR_IMAGE" || true
docker rmi -f "$BREAKOUT_IMAGE_NAME:$BREAKOUT_TAG" || true

# === Done ===
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))
echo "✅ Deploy complete in ${MINUTES}m ${SECONDS}s"
