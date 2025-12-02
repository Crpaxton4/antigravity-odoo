#!/bin/bash
# Script to create Kubernetes secrets from .env file

set -e

NAMESPACE="${1:-antigravity-dev}"
ENV_FILE="${2:-.env}"

echo "=========================================="
echo "Creating Kubernetes Secrets from .env"
echo "=========================================="
echo ""

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: $ENV_FILE not found"
    echo ""
    echo "Usage: $0 [namespace] [env-file]"
    echo "  namespace: Kubernetes namespace (default: antigravity-dev)"
    echo "  env-file:  Path to .env file (default: .env)"
    exit 1
fi

echo "Configuration:"
echo "  Namespace: $NAMESPACE"
echo "  Env File:  $ENV_FILE"
echo ""

# Function to get value from .env
get_env_value() {
    local key=$1
    grep "^${key}=" "$ENV_FILE" | cut -d '=' -f2- | tr -d '"' | tr -d "'"
}

# Extract values from .env
POSTGRES_PASSWORD=$(get_env_value "POSTGRES_PASSWORD")
POSTGRES_ADMIN_PASSWORD=$(get_env_value "POSTGRES_ADMIN_PASSWORD")
POSTGRES_ODOO_PASSWORD=$(get_env_value "POSTGRES_ODOO_PASSWORD")
POSTGRES_N8N_PASSWORD=$(get_env_value "POSTGRES_N8N_PASSWORD")
POSTGRES_GRAFANA_PASSWORD=$(get_env_value "POSTGRES_GRAFANA_PASSWORD")
PGADMIN_DEFAULT_PASSWORD=$(get_env_value "PGADMIN_DEFAULT_PASSWORD")
GF_SECURITY_ADMIN_PASSWORD=$(get_env_value "GF_SECURITY_ADMIN_PASSWORD")
N8N_ENCRYPTION_KEY=$(get_env_value "N8N_ENCRYPTION_KEY")
N8N_USER_MANAGEMENT_JWT_SECRET=$(get_env_value "N8N_USER_MANAGEMENT_JWT_SECRET")

# Validate required values
REQUIRED_VARS=(
    "POSTGRES_PASSWORD"
    "POSTGRES_ADMIN_PASSWORD"
    "POSTGRES_ODOO_PASSWORD"
    "POSTGRES_N8N_PASSWORD"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "❌ Error: Missing required environment variables in $ENV_FILE:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

echo "✓ All required variables found in .env"
echo ""

# Create namespace if it doesn't exist
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
echo "✓ Namespace $NAMESPACE ready"
echo ""

# Function to check if secret exists and matches
check_secret() {
    local secret_name=$1
    if kubectl get secret "$secret_name" -n "$NAMESPACE" &> /dev/null; then
        return 0  # exists
    else
        return 1  # doesn't exist
    fi
}

# Track if any secrets were updated
SECRETS_UPDATED=false

# Create PostgreSQL secret
echo "Creating postgresql-secrets..."
if check_secret "postgresql-secrets"; then
    echo "  Secret already exists, updating..."
    SECRETS_UPDATED=true
fi
kubectl create secret generic postgresql-secrets \
    --from-literal=postgres-password="$POSTGRES_PASSWORD" \
    --from-literal=admin-password="$POSTGRES_ADMIN_PASSWORD" \
    --from-literal=odoo-password="$POSTGRES_ODOO_PASSWORD" \
    --from-literal=n8n-password="$POSTGRES_N8N_PASSWORD" \
    --from-literal=grafana-password="${POSTGRES_GRAFANA_PASSWORD:-$POSTGRES_ADMIN_PASSWORD}" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f - > /dev/null

echo "✓ Created/Updated postgresql-secrets"

# Create Odoo secret
echo "Creating odoo-secrets..."
if check_secret "odoo-secrets"; then
    echo "  Secret already exists, updating..."
fi
kubectl create secret generic odoo-secrets \
    --from-literal=db-password="$POSTGRES_ODOO_PASSWORD" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f - > /dev/null

echo "✓ Created/Updated odoo-secrets"

# Create n8n secrets
echo "Creating n8n-secrets..."
if check_secret "n8n-secrets"; then
    echo "  Secret already exists, updating..."
fi
kubectl create secret generic n8n-secrets \
    --from-literal=db-password="$POSTGRES_N8N_PASSWORD" \
    --from-literal=encryption-key="${N8N_ENCRYPTION_KEY}" \
    --from-literal=jwt-secret="${N8N_USER_MANAGEMENT_JWT_SECRET}" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f - > /dev/null

echo "✓ Created/Updated n8n-secrets"

# Create pgAdmin secret
echo "Creating pgadmin-secrets..."
if check_secret "pgadmin-secrets"; then
    echo "  Secret already exists, updating..."
fi
kubectl create secret generic pgadmin-secrets \
    --from-literal=password="${PGADMIN_DEFAULT_PASSWORD:-admin}" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f - > /dev/null

echo "✓ Created/Updated pgadmin-secrets"

# Create Grafana secret
echo "Creating grafana-secrets..."
if check_secret "grafana-secrets"; then
    echo "  Secret already exists, updating..."
fi
kubectl create secret generic grafana-secrets \
    --from-literal=admin-password="${GF_SECURITY_ADMIN_PASSWORD:-admin}" \
    --from-literal=db-password="${POSTGRES_GRAFANA_PASSWORD:-$POSTGRES_ADMIN_PASSWORD}" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f - > /dev/null

echo "✓ Created/Updated grafana-secrets"

echo ""
echo "=========================================="
echo "Secrets Created Successfully!"
echo "=========================================="
echo ""
echo "Created secrets in namespace: $NAMESPACE"
kubectl get secrets -n "$NAMESPACE" | grep -E "(postgresql|odoo|n8n|pgadmin|grafana)-secrets"
echo ""

echo "Next steps:"
echo "1. Deploy with environment-aware HelmReleases:"
echo "   kubectl apply -f kubernetes/flux/releases/dev/"
echo ""
echo "2. Verify secrets are mounted:"
echo "   kubectl describe pod <pod-name> -n $NAMESPACE"
echo ""

# Optionally label secrets for Flux management
echo "Labeling secrets for Flux..."
kubectl label secret postgresql-secrets odoo-secrets n8n-secrets pgadmin-secrets grafana-secrets \
    app.kubernetes.io/managed-by=flux \
    --namespace="$NAMESPACE" \
    --overwrite > /dev/null 2>&1

echo "✓ Secrets labeled for Flux management"
echo ""
