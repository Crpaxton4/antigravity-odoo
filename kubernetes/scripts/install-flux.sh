#!/bin/bash
# Script to install Flux CD in Kubernetes cluster

set -e

# Detect if running in a terminal for color support
if [ -t 1 ]; then
    # Terminal detected - enable colors
    COLOR_INFO='\033[0;34m'
    COLOR_SUCCESS='\033[0;32m'
    COLOR_ERROR='\033[0;31m'
    COLOR_RESET='\033[0m'
else
    # Not a terminal - disable colors
    COLOR_INFO=''
    COLOR_SUCCESS=''
    COLOR_ERROR=''
    COLOR_RESET=''
fi

# Function to print status (POSIX-compliant with printf)
log_info() {
    printf "%b[INFO]%b %s\n" "${COLOR_INFO}" "${COLOR_RESET}" "$1"
}

log_success() {
    printf "%b[SUCCESS]%b %s\n" "${COLOR_SUCCESS}" "${COLOR_RESET}" "$1"
}

log_error() {
    printf "%b[ERROR]%b %s\n" "${COLOR_ERROR}" "${COLOR_RESET}" "$1" >&2
}

printf "%s\n" "Installing Flux CD..."

# Check if flux CLI is installed
if ! command -v flux &> /dev/null; then
    log_error "Flux CLI not found. Please install it first:"
    printf "  %s\n" "brew install fluxcd/tap/flux"
    printf "  %s\n" "or visit: https://fluxcd.io/flux/installation/"
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

printf "\n"
printf "%s\n" "Next steps:"
printf "%s\n" "1. Create namespace: kubectl create namespace antigravity-dev"
printf "%s\n" "2. Apply GitRepository: kubectl apply -f kubernetes/flux/sources/gitrepository.yaml"
printf "%s\n" "3. Apply HelmReleases: kubectl apply -f kubernetes/flux/releases/dev/"
printf "%s\n" "4. Watch reconciliation: flux get sources git"
printf "%s\n" "                         flux get helmreleases -A"

printf "\n"
printf "%s\n" "To bootstrap Flux with Git (recommended for production):"
printf "%s\n" "  flux bootstrap github \\"
printf "%s\n" "    --owner=YOUR_USERNAME \\"
printf "%s\n" "    --repository=antigravity-odoo \\"
printf "%s\n" "    --branch=main \\"
printf "%s\n" "    --path=./kubernetes/flux \\"
printf "%s\n" "    --personal"
