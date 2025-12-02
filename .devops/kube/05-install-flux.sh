#!/bin/bash
# Script to install Flux CD
# This is a copy of kubernetes/scripts/install-flux.sh for convenience

set -e

echo "=========================================="
echo "Installing Flux CD"
echo "=========================================="
echo ""

# Check if flux CLI is installed
if ! command -v flux &> /dev/null; then
    echo "❌ Flux CLI not found."
    echo ""
    echo "Install Flux CLI:"
    echo "  macOS:   brew install fluxcd/tap/flux"
    echo "  Linux:   curl -s https://fluxcd.io/install.sh | sudo bash"
    echo "  Windows: choco install flux"
    echo ""
    echo "Or visit: https://fluxcd.io/flux/installation/"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

echo "Pre-flight checks..."
flux check --pre

echo ""
echo "Installing Flux components..."
flux install

echo ""
echo "Waiting for Flux to be ready..."
kubectl wait --for=condition=ready pod -l app=source-controller -n flux-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=kustomize-controller -n flux-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=helm-controller -n flux-system --timeout=300s

echo ""
echo "✓ Flux installed successfully!"
echo ""

echo "=========================================="
echo "Flux Status"
echo "=========================================="
flux check
echo ""

echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Deploy services:"
echo "   ./06-deploy.sh"
echo ""
echo "Optional - Bootstrap Flux with Git (recommended for production):"
echo "  flux bootstrap github \\"
echo "    --owner=YOUR_USERNAME \\"
echo "    --repository=antigravity-odoo \\"
echo "    --branch=main \\"
echo "    --path=./kubernetes/flux \\"
echo "    --personal"
echo ""
