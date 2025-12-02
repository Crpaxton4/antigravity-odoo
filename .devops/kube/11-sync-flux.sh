#!/bin/bash
# Quick script to sync Flux and reconcile all resources
# Useful when you've pushed changes and want to trigger an immediate update

set -e

echo "=========================================="
echo "Syncing Flux with Git Repository"
echo "=========================================="
echo ""

# Force git source reconciliation
echo "1. Reconciling Git source..."
flux reconcile source git antigravity-odoo --timeout 2m

echo ""
echo "2. Reconciling HelmCharts..."
for chart in postgresql odoo n8n ollama pgadmin monitoring; do
    echo "  - Reconciling ${chart}..."
    flux reconcile source helmchart "antigravity-dev-${chart}" -n flux-system 2>/dev/null || true
done

echo ""
echo "3. Reconciling HelmReleases..."
for release in postgresql odoo n8n ollama pgadmin monitoring; do
    flux reconcile helmrelease "${release}" -n antigravity-dev 2>/dev/null || true
done

echo ""
echo "=========================================="
echo "Sync Complete!"
echo "=========================================="
echo ""

echo "Check status:"
echo "  flux get sources git"
echo "  flux get helmreleases -n antigravity-dev"
echo "  kubectl get pods -n antigravity-dev"
echo ""
