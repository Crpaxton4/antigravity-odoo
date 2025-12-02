#!/bin/bash
# Script to check deployment health and status

set -e

NAMESPACE="antigravity-dev"

echo "=========================================="
echo "Deployment Health Check"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check cluster connection
echo "1. Cluster Connection"
if kubectl cluster-info &> /dev/null; then
    echo -e "   ${GREEN}✓${NC} Connected to: $(kubectl config current-context)"
else
    echo -e "   ${RED}✗${NC} Cannot connect to cluster"
    exit 1
fi
echo ""

# Check Flux
echo "2. Flux Status"
if flux check &> /dev/null; then
    echo -e "   ${GREEN}✓${NC} Flux is healthy"
else
    echo -e "   ${RED}✗${NC} Flux has issues"
    flux check
fi
echo ""

# Check GitRepository
echo "3. Git Source"
GIT_STATUS=$(kubectl get gitrepository antigravity-odoo -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "NotFound")
if [ "$GIT_STATUS" = "True" ]; then
    echo -e "   ${GREEN}✓${NC} Git repository synced"
else
    echo -e "   ${RED}✗${NC} Git repository not ready"
    kubectl describe gitrepository antigravity-odoo -n flux-system | tail -20
fi
echo ""

# Check HelmReleases
echo "4. HelmReleases"
HELM_RELEASES=$(kubectl get helmrelease -n "$NAMESPACE" -o json 2>/dev/null || echo '{"items":[]}')
TOTAL=$(echo "$HELM_RELEASES" | jq '.items | length')
READY=$(echo "$HELM_RELEASES" | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')

echo "   Ready: $READY / $TOTAL"
echo ""

if [ $TOTAL -gt 0 ]; then
    echo "   Status by service:"
    kubectl get helmrelease -n "$NAMESPACE" -o custom-columns=NAME:.metadata.name,READY:.status.conditions[?\(@.type==\"Ready\"\)].status,MESSAGE:.status.conditions[?\(@.type==\"Ready\"\)].message
else
    echo -e "   ${YELLOW}⚠${NC} No HelmReleases found"
fi
echo ""

# Check Pods
echo "5. Pods"
POD_STATUS=$(kubectl get pods -n "$NAMESPACE" -o json 2>/dev/null || echo '{"items":[]}')
TOTAL_PODS=$(echo "$POD_STATUS" | jq '.items | length')
RUNNING_PODS=$(echo "$POD_STATUS" | jq '[.items[] | select(.status.phase=="Running")] | length')
READY_PODS=$(echo "$POD_STATUS" | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')

echo "   Running: $RUNNING_PODS / $TOTAL_PODS"
echo "   Ready:   $READY_PODS / $TOTAL_PODS"
echo ""

if [ $TOTAL_PODS -gt 0 ]; then
    kubectl get pods -n "$NAMESPACE"
else
    echo -e "   ${YELLOW}⚠${NC} No pods found"
fi
echo ""

# Check PVCs
echo "6. Persistent Volume Claims"
PVC_COUNT=$(kubectl get pvc -n "$NAMESPACE" -o json 2>/dev/null | jq '.items | length')
PVC_BOUND=$(kubectl get pvc -n "$NAMESPACE" -o json 2>/dev/null | jq '[.items[] | select(.status.phase=="Bound")] | length')

echo "   Bound: $PVC_BOUND / $PVC_COUNT"
if [ $PVC_COUNT -gt 0 ]; then
    kubectl get pvc -n "$NAMESPACE"
fi
echo ""

# Check HPAs
echo "7. Horizontal Pod Autoscalers"
HPA_COUNT=$(kubectl get hpa -n "$NAMESPACE" -o json 2>/dev/null | jq '.items | length')

if [ $HPA_COUNT -gt 0 ]; then
    kubectl get hpa -n "$NAMESPACE"
else
    echo "   No HPAs found (may not be created yet)"
fi
echo ""

# Check services
echo "8. Services"
kubectl get svc -n "$NAMESPACE"
echo ""

# Resource usage (if metrics available)
echo "9. Resource Usage"
if kubectl top node &> /dev/null; then
    echo "   Nodes:"
    kubectl top node
    echo ""
    echo "   Pods:"
    kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "   Metrics not available yet"
else
    echo "   Metrics server not ready yet"
fi
echo ""

# Recent events
echo "10. Recent Events"
kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
echo ""

echo "=========================================="
echo "Summary"
echo "=========================================="

# Overall health determination
if [ "$GIT_STATUS" = "True" ] && [ "$READY" -eq "$TOTAL" ] && [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ]; then
    echo -e "${GREEN}✓ All systems healthy!${NC}"
    echo ""
    echo "Services are ready. Access them with:"
    echo "  ./07-access-services.sh"
elif [ "$RUNNING_PODS" -lt "$TOTAL_PODS" ]; then
    echo -e "${YELLOW}⚠ Deployment in progress...${NC}"
    echo ""
    echo "Some pods are still starting. Wait a few minutes and check again:"
    echo "  ./08-health-check.sh"
    echo ""
    echo "Watch pods:"
    echo "  kubectl get pods -n $NAMESPACE -w"
else
    echo -e "${RED}✗ Issues detected${NC}"
    echo ""
    echo "Check Flux logs:"
    echo "  flux logs --all-namespaces"
    echo ""
    echo "Check pod logs:"
    echo "  kubectl logs -n $NAMESPACE <pod-name>"
fi

echo ""
