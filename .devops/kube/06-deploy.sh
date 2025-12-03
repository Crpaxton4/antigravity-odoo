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
    echo "❌ Flux not found"
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

# Create namespaces
echo "Creating namespaces..."
kubectl apply -f kubernetes/namespaces.yaml

echo "✓ Namespaces created"
echo ""

# Check if Flux CRDs are installed
echo "Checking Flux CRDs..."
if ! kubectl get crd gitrepositories.source.toolkit.fluxcd.io &> /dev/null; then
    echo "❌ Flux CRDs not found!"
    echo "   Please run ./05-install-flux.sh first to install Flux."
    exit 1
fi

echo "✓ Flux CRDs found"
echo ""

# Apply GitRepository source
echo "Applying GitRepository source..."
kubectl apply -f kubernetes/flux/sources/gitrepository.yaml

echo "✓ GitRepository source applied"
echo ""

# Wait for GitRepository to be ready
echo "Waiting for Git source to be ready..."
kubectl wait --for=condition=ready gitrepository/antigravity-odoo -n flux-system --timeout=120s || true

echo ""

# Deploy Kubernetes Dashboard infrastructure
echo "Deploying Kubernetes Dashboard..."
kubectl apply -f kubernetes/flux/repositories/kubernetes-dashboard.yaml
kubectl apply -f kubernetes/flux/infrastructure/kubernetes-dashboard.yaml

# Wait for namespace to be created by HelmRelease
echo "Waiting for kubernetes-dashboard namespace..."
timeout=30
while [ $timeout -gt 0 ]; do
    if kubectl get namespace kubernetes-dashboard &> /dev/null; then
        break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

# Now apply RBAC resources
kubectl apply -f kubernetes/flux/infrastructure/dashboard-rbac.yaml

echo "✓ Dashboard infrastructure applied"
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

# Show pods before reset
echo "Pods in $NAMESPACE:"
kubectl get pods -n "$NAMESPACE"
echo ""

# Always reset HelmReleases to ensure fresh deployment
echo "Resetting all HelmReleases for fresh deployment..."
EXISTING_RELEASES=$(kubectl get helmreleases -n "$NAMESPACE" -o name 2>/dev/null || true)

if [ -n "$EXISTING_RELEASES" ]; then
    echo "Deleting existing HelmReleases:"
    echo "$EXISTING_RELEASES" | while read -r release; do
        release_name=$(echo "$release" | cut -d'/' -f2)
        echo "  - $release_name"
    done
    
    kubectl delete helmreleases --all -n "$NAMESPACE" 2>/dev/null || true
    
    echo ""
    echo "Waiting for cleanup..."
    sleep 5
fi

echo "Applying fresh HelmReleases from Git..."
kubectl apply -f kubernetes/flux/releases/dev/

echo ""
echo "✓ HelmReleases applied fresh. Flux will deploy from latest Git commit."
echo ""
echo "Watch pods come up:"
echo "  kubectl get pods -n $NAMESPACE -w"
echo ""
echo "Check HelmRelease status:"
echo "  flux get helmreleases -n $NAMESPACE"

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
echo "   ./.devops/kube/07-access-services.sh"
echo ""
