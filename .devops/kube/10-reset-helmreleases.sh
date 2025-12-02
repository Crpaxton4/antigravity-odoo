#!/bin/bash
# Script to reset HelmReleases when they get stuck
# Useful when templates change or pods are in error states

set -euo pipefail

# Error handler for better debugging
error_handler() {
    local exit_code=$?
    local line_number=$1
    local bash_command=$2
    
    echo "" >&2
    echo "========================================" >&2
    echo "❌ ERROR: Script failed!" >&2
    echo "========================================" >&2
    echo "Exit Code:    $exit_code" >&2
    echo "Failed Line:  $line_number" >&2
    echo "Failed Command: $bash_command" >&2
    echo "========================================" >&2
    echo "" >&2
    
    exit "$exit_code"
}

# Set trap to catch errors
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

NAMESPACE="${1:-antigravity-dev}"
SERVICE="${2:-all}"

# Input validation and sanitization for SERVICE parameter
if [ "$SERVICE" != "all" ]; then
    # Check for path traversal attempts (../) and absolute paths
    if [[ "$SERVICE" == *".."* ]] || [[ "$SERVICE" == /* ]]; then
        echo "❌ Error: Invalid SERVICE parameter. Path traversal attempts are not allowed."
        exit 1
    fi
    
    # Validate SERVICE matches allowed pattern: alphanumeric, dots, underscores, hyphens only
    if ! [[ "$SERVICE" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo "❌ Error: Invalid SERVICE parameter. Only alphanumeric characters, dots, underscores, and hyphens are allowed."
        exit 1
    fi
    
    # Additional whitelist validation (optional but recommended)
    # Define known services to restrict to specific values
    ALLOWED_SERVICES=("odoo" "postgresql" "n8n" "ollama" "pgadmin" "grafana" "prometheus")
    SERVICE_ALLOWED=false
    for allowed in "${ALLOWED_SERVICES[@]}"; do
        if [ "$SERVICE" == "$allowed" ]; then
            SERVICE_ALLOWED=true
            break
        fi
    done
    
    if [ "$SERVICE_ALLOWED" != "true" ]; then
        echo "❌ Error: Unknown service '$SERVICE'. Allowed services: ${ALLOWED_SERVICES[*]}"
        exit 1
    fi
fi

echo "=========================================="
echo "Reset HelmReleases"
echo "=========================================="
echo ""
echo "Namespace: $NAMESPACE"
echo "Service:   $SERVICE"
echo ""

if [ "$SERVICE" == "all" ]; then
    echo "⚠️  This will delete and recreate ALL HelmReleases in $NAMESPACE"
    read -p "Are you sure? (y/N): " -r
    REPLY=$(echo "$REPLY" | xargs)  # Trim whitespace
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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
    
    # Define base directory to prevent path traversal
    BASE_DIR="kubernetes/flux/releases/dev"
    
    # Verify directory exists
    if [ ! -d "$BASE_DIR" ]; then
        echo "❌ Error: Base directory '$BASE_DIR' does not exist."
        exit 1
    fi
    
    kubectl apply -f "$BASE_DIR/"
    
else
    echo "Resetting HelmRelease: $SERVICE"
    read -p "Continue? (y/N): " -r
    REPLY=$(echo "$REPLY" | xargs)  # Trim whitespace
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
    
    # Define base directory to prevent path traversal
    BASE_DIR="kubernetes/flux/releases/dev"
    FILE_PATH="${BASE_DIR}/${SERVICE}.yaml"
    
    # Verify the file exists and is a regular file
    if [ ! -f "$FILE_PATH" ]; then
        echo "❌ Error: HelmRelease file '$FILE_PATH' does not exist or is not a regular file."
        exit 1
    fi
    
    # Verify the resolved path is still within the base directory (additional safety check)
    REAL_BASE=$(realpath "$BASE_DIR")
    REAL_FILE=$(realpath "$FILE_PATH")
    if [[ "$REAL_FILE" != "$REAL_BASE"/* ]]; then
        echo "❌ Error: Resolved file path '$REAL_FILE' is outside the allowed base directory."
        exit 1
    fi
    
    kubectl apply -f "$FILE_PATH"
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
