#!/bin/bash
# Access Kubernetes Dashboard

set -e

echo "=========================================="
echo "Kubernetes Dashboard Access"
echo "=========================================="
echo ""

# Check if dashboard is running
if ! kubectl get deployment kubernetes-dashboard -n kubernetes-dashboard &> /dev/null; then
    echo "❌ Kubernetes Dashboard is not deployed"
    echo ""
    echo "Deploy it first using:"
    echo "  kubectl apply -f kubernetes/flux/repositories/kubernetes-dashboard.yaml"
    echo "  kubectl apply -f kubernetes/flux/infrastructure/kubernetes-dashboard.yaml"
    echo "  kubectl apply -f kubernetes/flux/infrastructure/dashboard-rbac.yaml"
    exit 1
fi

# Wait for dashboard to be ready
echo "Checking dashboard status..."
kubectl wait --for=condition=available --timeout=60s deployment/kubernetes-dashboard -n kubernetes-dashboard || {
    echo "⚠️  Dashboard is not ready yet. Checking pods..."
    kubectl get pods -n kubernetes-dashboard
    exit 1
}

echo "✓ Dashboard is ready"
echo ""

# Get the admin token
echo "=========================================="
echo "Dashboard Bearer Token"
echo "=========================================="
echo ""
echo "Copy this token for login:"
echo ""

TOKEN=$(kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 --decode)
echo "$TOKEN"
echo ""

echo "=========================================="
echo "Access Dashboard"
echo "=========================================="
echo ""
echo "1. Start the proxy (in this window):"
echo "   kubectl proxy"
echo ""
echo "2. Open in your browser:"
echo "   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "3. Select 'Token' login and paste the token above"
echo ""

# Offer to start proxy
read -p "Start kubectl proxy now? (y/N): " START_PROXY

if [[ "$START_PROXY" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Starting kubectl proxy..."
    echo "Dashboard will be available at:"
    echo "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo ""
    echo "Press Ctrl+C to stop the proxy"
    echo ""
    kubectl proxy
else
    echo ""
    echo "Run 'kubectl proxy' manually when ready to access the dashboard"
fi
