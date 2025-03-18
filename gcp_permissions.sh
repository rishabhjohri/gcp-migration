#!/bin/bash
set -e  # Exit on error

PROJECT_ID="vcc-ass3"

echo "🔍 Checking currently authenticated user..."
gcloud auth list

echo "🔍 Checking current GCP project..."
CURRENT_PROJECT=$(gcloud config get-value project)
echo "Current Project: $CURRENT_PROJECT"

if [[ "$CURRENT_PROJECT" != "$PROJECT_ID" ]]; then
    echo "⚠️ Project mismatch! Setting project to $PROJECT_ID..."
    gcloud config set project "$PROJECT_ID"
fi

echo "🔐 Assigning Compute Engine permissions..."
USER_EMAIL=$(gcloud auth list --format="value(account)")

if [[ -z "$USER_EMAIL" ]]; then
    echo "❌ No authenticated user found. Please run 'gcloud auth login' manually."
    exit 1
fi

echo "✅ Adding Compute Admin role to $USER_EMAIL for project $PROJECT_ID..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="user:$USER_EMAIL" \
    --role="roles/compute.admin"

echo "🔄 Re-authenticating GCP..."
gcloud auth application-default login

echo "🔄 Re-authenticating for API calls..."
gcloud auth login

echo "✅ Permissions fixed! You can now create and list instances in $PROJECT_ID."

echo "🔄 Verifying permissions..."
gcloud compute instances list --limit=1

echo "✅ Done! Try running your script again."
