#!/bin/bash
# Script to create on-demand environments for testing/development

set -e

if [ -z "$1" ]; then
    echo "Usage: ./create-environment.sh ENVIRONMENT_NAME"
    echo "Example: ./create-environment.sh feature-auth"
    exit 1
fi

ENV_NAME="$1"
NAMESPACE="antigravity-${ENV_NAME}"

echo "Creating environment: ${ENV_NAME}"
echo "Namespace: ${NAMESPACE}"

# Create namespace
echo "Creating namespace..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Label namespace
kubectl label namespace "${NAMESPACE}" environment="${ENV_NAME}" --overwrite

# Create directory for environment-specific Flux releases
RELEASE_DIR="kubernetes/flux/releases/${ENV_NAME}"
mkdir -p "${RELEASE_DIR}"

# Copy HelmRelease templates from dev
echo "Creating HelmRelease manifests..."
for file in kubernetes/flux/releases/dev/*.yaml; do
    filename=$(basename "$file")
    sed "s/antigravity-dev/${NAMESPACE}/g" "$file" > "${RELEASE_DIR}/${filename}"
done

echo "✓ Environment '${ENV_NAME}' created!"
echo ""
echo "Next steps:"
echo "1. Review and customize: ${RELEASE_DIR}/*.yaml"
echo "2. Update passwords/secrets in the HelmRelease values"
echo "3. Apply releases: kubectl apply -f ${RELEASE_DIR}/"
echo "4. Watch deployment: flux get helmreleases -n ${NAMESPACE}"
echo ""
echo "To delete this environment:"
echo "  kubectl delete namespace ${NAMESPACE}"
echo "  rm -rf ${RELEASE_DIR}"
