#!/bin/bash
# Script to clean up and delete the deployment

set -e

NAMESPACE="antigravity-dev"

echo "=========================================="
echo "Cleanup Deployment"
echo "=========================================="
echo ""

echo "⚠️  WARNING: This will delete all resources in namespace: $NAMESPACE"
echo ""
read -p "Are you sure you want to continue? (yes/NO): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Deleting HelmReleases..."
kubectl delete helmrelease --all -n "$NAMESPACE" --wait=false

echo ""
echo "Waiting for Flux to clean up resources..."
sleep 10

echo ""
echo "Deleting namespace..."
kubectl delete namespace "$NAMESPACE"

echo ""
echo "Deleting Flux GitRepository source..."
kubectl delete gitrepository antigravity-odoo -n flux-system 2>/dev/null || true

echo ""
echo "✓ Cleanup complete!"
echo ""

read -p "Do you want to uninstall Flux as well? (yes/NO): " FLUX_CONFIRM

if [ "$FLUX_CONFIRM" = "yes" ]; then
    echo ""
    echo "Uninstalling Flux..."
    flux uninstall --silent
    echo "✓ Flux uninstalled"
fi

echo ""
read -p "Do you want to delete the Minikube cluster? (yes/NO): " MINIKUBE_CONFIRM

if [ "$MINIKUBE_CONFIRM" = "yes" ]; then
    echo ""
    echo "Deleting Minikube cluster..."
    minikube delete
    echo "✓ Minikube cluster deleted"
fi

echo ""
echo "=========================================="
echo "Cleanup Complete"
echo "=========================================="
echo ""
