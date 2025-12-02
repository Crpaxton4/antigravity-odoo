#!/bin/bash
# Master deployment script - runs all steps in sequence
# Use with caution - this will deploy the entire stack

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Antigravity Odoo - Kubernetes Deployment"
echo "Master Automation Script"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "$SCRIPT_DIR/02-setup-cluster.sh" ]; then
    echo "❌ Error: Script must be run from .devops/kube directory"
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

read -p "Continue with automated deployment? (yes/NO): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled."
    echo ""
    echo "To run steps manually:"
    echo "  ./02-setup-cluster.sh"
    echo "  ./03-update-secrets.sh"
    echo "  ./04-update-git-repo.sh"
    echo "  ./05-install-flux.sh"
    echo "  ./06-deploy.sh"
    exit 0
fi

echo ""
echo "=========================================="
echo "Step 1/5: Setting up cluster"
echo "=========================================="
./02-setup-cluster.sh

echo ""
echo "=========================================="
echo "Step 2/5: Updating secrets"
echo "=========================================="
# Auto-generate passwords by passing 'y'
echo "y" | ./03-update-secrets.sh

echo ""
echo "=========================================="
echo "Step 3/5: Updating Git repository"
echo "=========================================="
read -p "Enter your Git repository URL: " GIT_URL
echo "$GIT_URL" | ./04-update-git-repo.sh

echo ""
echo "=========================================="
echo "Step 4/5: Installing Flux"
echo "=========================================="
./05-install-flux.sh

echo ""
echo "⚠️  IMPORTANT: Start minikube tunnel in a separate terminal NOW!"
echo "  Run: minikube tunnel"
echo ""
read -p "Press Enter when tunnel is running..."

echo ""
echo "=========================================="
echo "Step 5/5: Deploying services"
echo "=========================================="
./06-deploy.sh

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Wait for pods to be ready (5-10 minutes):"
echo "   ./08-health-check.sh"
echo ""
echo "2. Access services:"
echo "   ./07-access-services.sh"
echo ""
echo "3. Monitor deployment:"
echo "   kubectl get pods -n antigravity-dev -w"
echo "   flux logs --follow"
echo ""
