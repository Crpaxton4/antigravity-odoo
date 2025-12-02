#!/bin/bash
# Script to reset HelmReleases when they get stuck
# Useful when templates change or pods are in error states

set -e

NAMESPACE="${1:-antigravity-dev}"
SERVICE="${2:-all}"

echo "=========================================="
echo "Reset HelmReleases"
echo "=========================================="
echo ""
echo "Namespace: $NAMESPACE"
echo "Service:   $SERVICE"
echo ""

if [ "$SERVICE" == "all" ]; then
    echo "⚠️  This will delete and recreate ALL HelmReleases in $NAMESPACE"
    read -p "Are you sure? (yes/NO): " -r
    if [ "$REPLY" != "yes" ]; then
        echo "Cancelled."
        exit 0
    fi
    
    echo ""
    echo "Deleting all HelmReleases..."
    kubectl delete helmrelease --all -n "$NAMESPACE"
    
    echo "Waiting for cleanup..."
    sleep 5
    
    echo ""
    echo "Reapplying HelmReleases..."
    kubectl apply -f kubernetes/flux/releases/dev/
    
else
    echo "Resetting HelmRelease: $SERVICE"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    echo ""
    echo "Deleting HelmRelease $SERVICE..."
    kubectl delete helmrelease "$SERVICE" -n "$NAMESPACE"
    
    echo "Waiting for cleanup..."
    sleep 3
    
    echo ""
    echo "Reapplying HelmRelease..."
    kubectl apply -f "kubernetes/flux/releases/dev/${SERVICE}.yaml"
fi

echo ""
echo "=========================================="
echo "Watching Deployment"
echo "=========================================="
echo ""

echo "HelmReleases:"
flux get helmreleases -n "$NAMESPACE"

echo ""
echo "Pods:"
kubectl get pods -n "$NAMESPACE"

echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "Watch pods come up:"
echo "  kubectl get pods -n $NAMESPACE -w"
echo ""
echo "Check HelmRelease status:"
echo "  flux get helmreleases -n $NAMESPACE"
echo ""
echo "Run health check:"
echo "  ./08-health-check.sh"
echo ""
