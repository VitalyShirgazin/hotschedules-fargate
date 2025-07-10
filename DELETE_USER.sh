#!/bin/bash
set -e

# === Prompt for USER ID ===
read -p "👤 Enter the USER_ID to delete: " USER_ID
USER_DIR="./break/users/$USER_ID"

# === Validate path ===
if [ ! -d "$USER_DIR" ]; then
  echo "❌ ERROR: Directory $USER_DIR does not exist."
  exit 1
fi

# === Confirm delete ===
read -p "⚠️ Are you sure you want to delete user '$USER_ID'? This will destroy infrastructure and remove files. (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "❌ Aborted."
  exit 1
fi

# === Step 1: Destroy Terraform-managed resources ===
echo "🧨 Running terraform destroy for $USER_ID..."
cd "$USER_DIR"
terraform init -input=false > /dev/null
terraform destroy -auto-approve
cd - > /dev/null

# === Step 2: Delete user folder ===
echo "🧹 Deleting user directory $USER_DIR..."
rm -rf "$USER_DIR"

echo "✅ User '$USER_ID' has been fully deleted."
