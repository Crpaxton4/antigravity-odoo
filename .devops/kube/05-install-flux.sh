#!/bin/bash
# Script to install Flux CD
# This is a copy of kubernetes/scripts/install-flux.sh for convenience

set -e

echo "=========================================="
echo "Installing Flux CD"
echo "=========================================="
echo ""

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

# Check if flux CLI is installed
if ! command -v flux &> /dev/null; then
    log_error "Flux CLI not found."
    echo ""
    echo "Install Flux CLI:"
    echo "  macOS:   brew install fluxcd/tap/flux"
    echo "  Linux:   curl -s https://fluxcd.io/install.sh | sudo bash"
    echo "  Windows: choco install flux"
    echo ""
    echo "Or visit: https://fluxcd.io/flux/installation/"
    exit 1
fi

FLUX_VERSION=$(flux --version)
log_info "Found Flux CLI: $FLUX_VERSION"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl first."
    exit 1
fi

log_info "Running pre-flight checks..."
if ! flux check --pre; then
    log_error "Pre-flight checks failed. Please resolve the issues above."
    exit 1
fi

echo ""
log_info "Step 1: Installing Flux components and CRDs..."
echo "Running: flux install"
echo "----------------------------------------"

# Install Flux components and CRDs
if flux install; then
    echo "----------------------------------------"
    log_success "Flux installation command completed."
else
    echo "----------------------------------------"
    log_error "Flux installation failed."
    
    echo ""
    log_info "Debugging Flux installation failure..."
    
    echo "1. Pod Status:"
    kubectl get pods -n flux-system
    
    echo ""
    echo "2. Source Controller Events:"
    kubectl describe deployment source-controller -n flux-system
    
    echo ""
    echo "3. Source Controller Logs:"
    kubectl logs -l app=source-controller -n flux-system --tail=50
    
    exit 1
fi

echo ""
log_info "Step 2: Waiting for Flux components to be ready..."
TIMEOUT=300s

log_info "Waiting for source-controller..."
kubectl wait --for=condition=ready pod -l app=source-controller -n flux-system --timeout=$TIMEOUT

log_info "Waiting for kustomize-controller..."
kubectl wait --for=condition=ready pod -l app=kustomize-controller -n flux-system --timeout=$TIMEOUT

log_info "Waiting for helm-controller..."
kubectl wait --for=condition=ready pod -l app=helm-controller -n flux-system --timeout=$TIMEOUT

log_success "All Flux controllers are ready."

echo ""
log_info "Step 3: Verifying CRD installation..."

CRDS=(
    "gitrepositories.source.toolkit.fluxcd.io"
    "helmreleases.helm.toolkit.fluxcd.io"
    "helmcharts.source.toolkit.fluxcd.io"
    "helmrepositories.source.toolkit.fluxcd.io"
)

MISSING_CRDS=0

for crd in "${CRDS[@]}"; do
    if kubectl get crd "$crd" &> /dev/null; then
        log_success "CRD found: $crd"
    else
        log_error "CRD missing: $crd"
        MISSING_CRDS=$((MISSING_CRDS + 1))
    fi
done

if [ $MISSING_CRDS -gt 0 ]; then
    log_error "$MISSING_CRDS CRDs are missing. Installation incomplete."
    echo ""
    echo "Troubleshooting:"
    echo "1. Check if you have permissions to install CRDs."
    echo "2. Try running 'flux install' manually to see detailed errors."
    echo "3. Ensure your Kubernetes cluster is healthy."
    exit 1
fi

echo ""
log_success "Flux installed and verified successfully!"
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
