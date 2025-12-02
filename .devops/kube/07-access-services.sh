#!/bin/bash
# Script to get service access URLs

set -e

NAMESPACE="antigravity-dev"

echo "=========================================="
echo "Service Access Information"
echo "=========================================="
echo ""

# Check if using Minikube
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    IS_MINIKUBE=true
    echo "Detected Minikube cluster"
    echo ""
    
    # Check if tunnel is running
    if ! pgrep -f "minikube tunnel" > /dev/null; then
        echo "⚠️  Minikube tunnel is not running!"
        echo ""
        echo "LoadBalancer services require tunnel. Start it with:"
        echo "  minikube tunnel"
        echo ""
        echo "(Run in a separate terminal and keep it running)"
        echo ""
        read -p "Press Enter to continue..."
    fi
else
    IS_MINIKUBE=false
fi

echo "Fetching service information..."
echo ""

# Get all LoadBalancer services
SERVICES=$(kubectl get svc -n "$NAMESPACE" -o json | jq -r '.items[] | select(.spec.type=="LoadBalancer") | .metadata.name')

if [ -z "$SERVICES" ]; then
    echo "❌ No LoadBalancer services found in namespace $NAMESPACE"
    echo ""
    echo "Make sure services are deployed:"
    echo "  kubectl get svc -n $NAMESPACE"
    exit 1
fi

# Function to get service URL
get_service_url() {
    local service=$1
    local port=$(kubectl get svc "$service" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')
    
    if [ "$IS_MINIKUBE" = true ]; then
        # Use minikube service URL
        minikube service "$service" -n "$NAMESPACE" --url 2>/dev/null || echo "Pending..."
    else
        # Get external IP
        local external_ip=$(kubectl get svc "$service" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [ -z "$external_ip" ]; then
            external_ip=$(kubectl get svc "$service" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        fi
        
        if [ -n "$external_ip" ]; then
            echo "http://${external_ip}:${port}"
        else
            echo "Pending..."
        fi
    fi
}

# Display service URLs
echo "Services:"
echo ""

for service in $SERVICES; do
    url=$(get_service_url "$service")
    printf "  %-15s %s\n" "$service:" "$url"
done

echo ""
echo "=========================================="
echo "Port Forwarding (Alternative)"
echo "=========================================="
echo ""
echo "If LoadBalancer is not working, use port-forward:"
echo ""
echo "  # Odoo"
echo "  kubectl port-forward svc/odoo 8069:8069 -n $NAMESPACE"
echo ""
echo "  # n8n"
echo "  kubectl port-forward svc/n8n 5678:5678 -n $NAMESPACE"
echo ""
echo "  # Grafana"
echo "  kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE"
echo ""
echo "  # pgAdmin"
echo "  kubectl port-forward svc/pgadmin 5050:80 -n $NAMESPACE"
echo ""
echo "  # Prometheus"
echo "  kubectl port-forward svc/prometheus 9090:9090 -n $NAMESPACE"
echo ""

echo "=========================================="
echo "Default Credentials"
echo "=========================================="
echo ""
echo "Odoo:"
echo "  Initial setup required on first access"
echo ""
echo "Grafana:"
echo "  Username: admin"
echo "  Password: (check HelmRelease values or .devops/kube/.secrets.txt)"
echo ""
echo "pgAdmin:"
echo "  Email: admin@localhost.com"
echo "  Password: (check HelmRelease values)"
echo ""
