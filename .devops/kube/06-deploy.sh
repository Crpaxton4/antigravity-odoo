#!/bin/bash
# Script to deploy all services to Kubernetes

set -e

echo "=========================================="
echo "Deploying Antigravity Odoo Stack"
echo "=========================================="
echo ""

NAMESPACE="antigravity-dev"

# Check prerequisites
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found"
    exit 1
fi

if ! command -v flux &> /dev/null; then
    echo "❌ Flux not found. Run ./05-install-flux.sh first"
    exit 1
fi

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "   Make sure your cluster is running (minikube start)"
    exit 1
fi

echo "Cluster: $(kubectl config current-context)"
echo "Namespace: $NAMESPACE"
echo ""

# Create namespace
echo "Creating namespace $NAMESPACE..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NAMESPACE" environment=development managed-by=flux --overwrite

echo "✓ Namespace created"
echo ""

# Apply GitRepository source
echo "Applying GitRepository source..."
kubectl apply -f kubernetes/flux/sources/gitrepository.yaml

echo "✓ GitRepository source applied"
echo ""

# Wait for GitRepository to be ready
echo "Waiting for Git source to be ready..."
kubectl wait --for=condition=ready gitrepository/antigravity-odoo -n flux-system --timeout=60s || true

echo ""

# Apply HelmReleases
echo "Deploying services via HelmReleases..."
kubectl apply -f kubernetes/flux/releases/dev/

echo "✓ HelmReleases applied"
echo ""

# Watch deployment
echo "=========================================="
echo "Deployment Status"
echo "=========================================="
echo ""
echo "Watching deployment... (Ctrl+C to stop watching)"
echo ""

sleep 5

# Show Flux status
flux get sources git
echo ""
flux get helmreleases -n "$NAMESPACE"
echo ""

# Show pods
echo "Pods in $NAMESPACE:"
kubectl get pods -n "$NAMESPACE"
echo ""

echo "=========================================="
echo "Monitoring Commands"
echo "=========================================="
echo ""
echo "Watch Flux reconciliation:"
echo "  flux logs --follow"
echo ""
echo "Watch pods:"
echo "  kubectl get pods -n $NAMESPACE -w"
echo ""
echo "Watch HelmReleases:"
echo "  watch flux get helmreleases -n $NAMESPACE"
echo ""
echo "Check specific service:"
echo "  kubectl logs -f -l app=postgresql -n $NAMESPACE"
echo ""

echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Wait for all pods to be ready (may take 5-10 minutes)"
echo "   kubectl get pods -n $NAMESPACE -w"
echo ""
echo "2. Once ready, access services:"
echo "   ./07-access-services.sh"
echo ""
