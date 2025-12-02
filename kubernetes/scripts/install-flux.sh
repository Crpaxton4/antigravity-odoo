#!/bin/bash
# Script to install Flux CD in Kubernetes cluster

set -e

# Function to print status
log_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

echo "Installing Flux CD..."

# Check if flux CLI is installed
if ! command -v flux &> /dev/null; then
    log_error "Flux CLI not found. Please install it first:"
    echo "  brew install fluxcd/tap/flux"
    echo "  or visit: https://fluxcd.io/flux/installation/"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl first."
    exit 1
fi

log_info "Pre-flight checks..."
flux check --pre

log_info "Installing Flux components..."
flux install

log_info "Waiting for Flux to be ready..."
kubectl wait --for=condition=ready pod -l app=source-controller -n flux-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=kustomize-controller -n flux-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=helm-controller -n flux-system --timeout=300s

log_success "Flux installed successfully!"

echo ""
echo "Next steps:"
echo "1. Create namespace: kubectl create namespace antigravity-dev"
echo "2. Apply GitRepository: kubectl apply -f kubernetes/flux/sources/gitrepository.yaml"
echo "3. Apply HelmReleases: kubectl apply -f kubernetes/flux/releases/dev/"
echo "4. Watch reconciliation: flux get sources git"
echo "                         flux get helmreleases -A"

echo ""
echo "To bootstrap Flux with Git (recommended for production):"
echo "  flux bootstrap github \\"
echo "    --owner=YOUR_USERNAME \\"
echo "    --repository=antigravity-odoo \\"
echo "    --branch=main \\"
echo "    --path=./kubernetes/flux \\"
echo "    --personal"
