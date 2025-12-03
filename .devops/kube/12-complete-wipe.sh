#!/bin/bash
# Complete wipe of Kubernetes deployment
# This will delete EVERYTHING in the namespace including persistent data

set -e

NAMESPACE="${1:-antigravity-dev}"

echo "=========================================="
echo "COMPLETE KUBERNETES WIPE"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will delete EVERYTHING in namespace: $NAMESPACE"
echo "   - All pods and deployments"
echo "   - All services and ingresses"
echo "   - All HelmReleases"
echo "   - All PVCs (PERMANENT DATA LOSS)"
echo "   - All secrets"
echo ""
echo "This is IRREVERSIBLE!"
echo ""

# If running non-interactively or with --force, skip confirmation
if [[ "$2" != "--force" ]]; then
    read -p "Type 'DELETE EVERYTHING' to confirm: " confirm
    if [[ "$confirm" != "DELETE EVERYTHING" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo ""
echo "Starting complete wipe of $NAMESPACE..."
echo ""

# 1. Delete all HelmReleases first (this prevents Flux from recreating resources)
echo "Step 1: Deleting all HelmReleases..."
if kubectl get helmreleases -n "$NAMESPACE" &> /dev/null; then
    kubectl delete helmreleases --all -n "$NAMESPACE" --timeout=30s || true
    echo "✓ HelmReleases deleted"
else
    echo "  No HelmReleases found"
fi
echo ""

# 2. Force delete all pods (don't wait for graceful shutdown)
echo "Step 2: Force deleting all pods..."
if kubectl get pods -n "$NAMESPACE" &> /dev/null; then
    kubectl delete pods --all -n "$NAMESPACE" --force --grace-period=0 --timeout=30s || true
    echo "✓ Pods deleted"
else
    echo "  No pods found"
fi
echo ""

# 3. Delete all StatefulSets (which manage PostgreSQL)
echo "Step 3: Deleting StatefulSets..."
if kubectl get statefulsets -n "$NAMESPACE" &> /dev/null; then
    kubectl delete statefulsets --all -n "$NAMESPACE" --timeout=30s || true
    echo "✓ StatefulSets deleted"
else
    echo "  No StatefulSets found"
fi
echo ""

# 4. Delete all Deployments
echo "Step 4: Deleting Deployments..."
if kubectl get deployments -n "$NAMESPACE" &> /dev/null; then
    kubectl delete deployments --all -n "$NAMESPACE" --timeout=30s || true
    echo "✓ Deployments deleted"
else
    echo "  No Deployments found"
fi
echo ""

# 5. Wait a moment for pods to terminate
echo "Waiting for resources to terminate..."
sleep 3
echo ""

# 6. Delete all PVCs (THIS DELETES ALL DATA)
echo "Step 5: Deleting all PVCs (PERMANENT DATA LOSS)..."
if kubectl get pvc -n "$NAMESPACE" &> /dev/null; then
    # Remove PVC finalizers if they're stuck
    for pvc in $(kubectl get pvc -n "$NAMESPACE" -o name 2>/dev/null); do
        kubectl patch "$pvc" -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge || true
    done
    kubectl delete pvc --all -n "$NAMESPACE" --timeout=30s || true
    echo "✓ PVCs deleted (all data wiped)"
else
    echo "  No PVCs found"
fi
echo ""

# 7. Delete all Services
echo "Step 6: Deleting Services..."
if kubectl get services -n "$NAMESPACE" &> /dev/null; then
    kubectl delete services --all -n "$NAMESPACE" --timeout=30s || true
    echo "✓ Services deleted"
else
    echo "  No Services found"
fi
echo ""

# 8. Delete all Secrets (we'll recreate them from .env)
echo "Step 7: Deleting Secrets..."
if kubectl get secrets -n "$NAMESPACE" &> /dev/null; then
    kubectl delete secrets --all -n "$NAMESPACE" --timeout=30s || true
    echo "✓ Secrets deleted"
else
    echo "  No Secrets found"
fi
echo ""

# 9. Delete all ConfigMaps
echo "Step 8: Deleting ConfigMaps..."
if kubectl get configmaps -n "$NAMESPACE" &> /dev/null; then
    kubectl delete configmaps --all -n "$NAMESPACE" --timeout=30s || true
    echo "✓ ConfigMaps deleted"
else
    echo "  No ConfigMaps found"
fi
echo ""

# 10. Delete and recreate the namespace for a completely clean slate
echo "Step 9: Recreating namespace for complete clean slate..."
kubectl delete namespace "$NAMESPACE" --timeout=60s || true
sleep 2
kubectl create namespace "$NAMESPACE" || true
echo "✓ Namespace recreated"
echo ""

echo "=========================================="
echo "WIPE COMPLETE!"
echo "=========================================="
echo ""
echo "Namespace $NAMESPACE has been completely wiped."
echo "All data has been permanently deleted."
echo ""
echo "Next steps:"
echo "1. Run secrets creation: ./.devops/kube/00-create-secrets-from-env.sh"
echo "2. Deploy services: ./.devops/kube/06-deploy.sh"
echo "   OR run full deployment: ./.devops/kube/01-deploy-all.sh"
echo ""
