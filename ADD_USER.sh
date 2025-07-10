#!/bin/bash
set -e

# === PROMPT USER-SPECIFIC CONFIG ===
read -p "Enter USER_ID: " USER_ID
read -p "Enter USERNAME: " USERNAME
read -p "Enter PASSWORD: " PASSWORD
read -p "Enter POS_ID: " POS_ID
read -p "Enter TO_EMAIL: " TO_EMAIL

echo ""
echo "You entered:"
echo "USER_ID     = $USER_ID"
echo "USERNAME    = $USERNAME"
echo "PASSWORD    = $PASSWORD"
echo "POS_ID      = $POS_ID"
echo "TO_EMAIL    = $TO_EMAIL"
echo ""

read -p "✅ Would you like to add new user with these values? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "❌ Aborted."
  exit 1
fi

# === FIXED SHARED CONFIG ===
AWS_REGION="CHANGE_ME"                        # <=== INSERT YOUR AWS REGION
AWS_ACCOUNT_ID="CHANGE_ME"                    # <=== INSERT YOUR AWS ID ACCOUNT NUMBER
CLUSTER_NAME="break-cluster"

TASK_FAMILY_IN="break-in-$USER_ID"
TASK_FAMILY_OUT="break-out-$USER_ID"

# === THIS IS ADMINISTRATORS EMAIL, NOT USERS  SEE README.md===
GMAIL_USER="CHANGE_ME@CHANGE_ME.com"
GMAIL_PASS="CHANGE_ME"

ECR_IMAGE_BREAK_IN="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/break-in"
ECR_IMAGE_BREAK_OUT="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/break-out"

CLUSTER_ARN="arn:aws:ecs:$AWS_REGION:$AWS_ACCOUNT_ID:cluster/$CLUSTER_NAME"
EXEC_ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole"
INVOKE_ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/eventbridge_invoke_ecs"

SUBNETS=(
  "subnet-CHANGE_ME"    # < === CHANGE TO REAL ID NUMBERS OF YOUR SUBNETS
  "subnet-CHANGE_ME"
  "subnet-CHANGE_ME"
  "subnet-CHANGE_ME"
  "subnet-CHANGE_ME"
  "subnet-CHANGE_ME"
)

SUBNET_IN="${SUBNETS[$RANDOM % ${#SUBNETS[@]}]}"
SUBNET_OUT="${SUBNETS[$RANDOM % ${#SUBNETS[@]}]}"

# === Step 1: Create user folder and copy template ===
USER_DIR="./break/users/$USER_ID"
mkdir -p "$USER_DIR"
cp ./break/users/sample/main.tf "$USER_DIR/main.tf"

# === Step 2: Generate terraform.tfvars ===
echo "🔧 Creating terraform.tfvars for $USER_ID..."
cat > "$USER_DIR/terraform.tfvars" <<EOF
user                 = "$USER_ID"
username             = "$USERNAME"
password             = "$PASSWORD"
pos_id               = "$POS_ID"
gmail_user           = "$GMAIL_USER"
gmail_pass           = "$GMAIL_PASS"
to_email             = "$TO_EMAIL"
subnets              = [$(printf '"%s", ' "${SUBNETS[@]}" | sed 's/, $//')]
ecr_image_break_in   = "$ECR_IMAGE_BREAK_IN"
ecr_image_break_out  = "$ECR_IMAGE_BREAK_OUT"
cluster_arn          = "$CLUSTER_ARN"
execution_role_arn   = "$EXEC_ROLE_ARN"
invoke_role_arn      = "$INVOKE_ROLE_ARN"
EOF

# === Step 3: Deploy the user's scheduled tasks (both break-in and break-out) ===
echo "🚀 Running terraform for $USER_ID..."
cd "$USER_DIR"
terraform init
terraform apply -auto-approve
cd - > /dev/null

echo "✅ All done: User $USER_ID set up with break-in and break-out tasks."
