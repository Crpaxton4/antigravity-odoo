# Function to run command with description
run_cmd() {
    echo "Running: $1"
    echo -e "\n========================================" >> troubleshoot.log
    echo "Command: $1" >> troubleshoot.log
    echo "========================================" >> troubleshoot.log
    eval "$2" >> troubleshoot.log 2>&1
}

echo "Starting troubleshooting... Output will be saved to troubleshoot.log"

# Get pod details
run_cmd "Get pod details" "kubectl get pods -n antigravity-dev"

# Describe the odoo pod (replace with actual pod name)
run_cmd "Describe odoo pod" "kubectl describe pod -l app=odoo -n antigravity-dev"

# Check pod logs
run_cmd "Check odoo pod logs" "kubectl logs -l app=odoo -n antigravity-dev"

# Check previous container logs if restarting
run_cmd "Check previous odoo pod logs" "kubectl logs -l app=odoo -n antigravity-dev --previous"

# Verify the secret has db-user
run_cmd "Verify odoo-secrets" "kubectl get secret odoo-secrets -n antigravity-dev -o yaml"

# Check what keys are in the secret
run_cmd "Check secret keys" "kubectl get secret odoo-secrets -n antigravity-dev -o jsonpath='{.data}' | jq 'keys'"

# Get HelmChart status
run_cmd "Get HelmChart status" "kubectl get helmchart antigravity-dev-monitoring -n flux-system -o yaml"

# Check Flux logs for monitoring errors
run_cmd "Check Flux logs for monitoring" "flux logs --kind=HelmChart --name=antigravity-dev-monitoring -n flux-system"

# Force reconcile all resources
run_cmd "Reconcile git source" "flux reconcile source git antigravity-odoo"

run_cmd "Reconcile odoo helmrelease" "flux reconcile helmrelease odoo -n antigravity-dev"

# Watch Flux logs in real-time
run_cmd "Watch Flux logs" "flux logs --follow --all-namespaces"

# Recent events for the namespace
run_cmd "Recent events in antigravity-dev" "kubectl get events -n antigravity-dev --sort-by='.lastTimestamp' | tail -20"

# All resources at once
run_cmd "Get all resources" "kubectl get all -n antigravity-dev"

run_cmd "Get helm resources" "kubectl get helmreleases,helmcharts -n antigravity-dev"