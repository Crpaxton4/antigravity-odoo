#!/bin/bash
# Master deployment script - runs all steps in sequence
# Use with caution - this will deploy the entire stack

set -e

SCRIPT_DIR="./.devops/kube/"

echo "=========================================="
echo "Antigravity Odoo - Kubernetes Deployment"
echo "Master Automation Script"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "$SCRIPT_DIR/02-setup-cluster.sh" ]; then
    echo "❌ Error: Script must be present in .devops/kube directory"
    exit 1
fi

echo "This script will:"
echo "  1. Setup Minikube cluster"
echo "  2. Update secrets (auto-generate passwords)"
echo "  3. Update Git repository URL"
echo "  4. Install Flux CD"
echo "  5. Deploy all services"
echo ""
echo "⚠️  Note: You'll still need to run 'minikube tunnel' in a separate terminal"
echo ""

read -p "Do you want to COMPLETELY WIPE the existing deployment first? (yes/NO): " WIPE_CONFIRM

if [ "$WIPE_CONFIRM" = "yes" ]; then
    echo ""
    echo "⚠️  WARNING: You are about to PERMANENTLY DELETE all data!"
    echo "   This will wipe all pods, PVCs, secrets, and persistent data."
    echo ""
    read -p "Type 'DELETE EVERYTHING' to confirm complete wipe: " WIPE_FINAL
    
    if [ "$WIPE_FINAL" = "DELETE EVERYTHING" ]; then
        echo ""
        echo "==========================================="
        echo "Step 0/5: Complete Wipe"
        echo "==========================================="
        ./.devops/kube/12-complete-wipe.sh antigravity-dev --force
        echo ""
        echo "✓ Wipe complete. Starting fresh deployment..."
        sleep 2
    else
        echo "Wipe cancelled. Proceeding with normal deployment..."
    fi
fi

echo ""
read -p "Continue with deployment? (yes/NO): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled."
    echo ""
    echo "To run steps manually:"
    echo "  ./.devops/kube/02-setup-cluster.sh"
    echo "  ./.devops/kube/03-update-secrets.sh"
    echo "  ./.devops/kube/04-update-git-repo.sh"
    echo "  ./.devops/kube/05-install-flux.sh"
    echo "  ./.devops/kube/06-deploy.sh"
    exit 0
fi

echo ""
echo "=========================================="
echo "Step 1/5: Setting up cluster"
echo "=========================================="
./.devops/kube/02-setup-cluster.sh

echo ""
echo "=========================================="
echo "Step 2/5: Updating secrets"
echo "=========================================="
# Check if .env exists, if so use it
if [ -f "../../.env" ] || [ -f ".env" ]; then
    echo "Found .env file, creating secrets..."
    ./.devops/kube/00-create-secrets-from-env.sh
else
    # Auto-generate passwords by passing 'y'
    echo "y" | ./.devops/kube/03-update-secrets.sh
fi

echo ""
echo "=========================================="
echo "Step 3/5: Updating Git repository"
echo "=========================================="
read -p "Enter your Git repository URL: " GIT_URL
./.devops/kube/04-update-git-repo.sh "$GIT_URL"

echo ""
echo "=========================================="
echo "Step 4/5: Installing Flux CD"
echo "=========================================="
./.devops/kube/05-install-flux.sh

echo ""
echo "⚠️  IMPORTANT: Start minikube tunnel in a separate terminal NOW!"
echo "  Run: minikube tunnel"
echo ""
read -p "Press Enter when tunnel is running..."

echo ""
echo "=========================================="
echo "Step 5/5: Deploying services"
echo "=========================================="
./.devops/kube/06-deploy.sh

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Wait for pods to be ready (5-10 minutes):"
echo "   ./.devops/kube/08-health-check.sh"
echo ""
echo "2. Access services:"
echo "   ./.devops/kube/07-access-services.sh"
echo ""
echo "3. Monitor deployment:"
echo "   kubectl get pods -n antigravity-dev -w"
echo "   flux logs --follow"
echo ""
