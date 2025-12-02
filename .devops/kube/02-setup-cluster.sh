#!/bin/bash
# Script to set up Minikube cluster for Antigravity Odoo

set -e

echo "=========================================="
echo "Setting up Minikube Cluster"
echo "=========================================="
echo ""

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube is not installed."
    echo ""
    echo "Install Minikube:"
    echo "  macOS:   brew install minikube"
    echo "  Linux:   curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
    echo "           sudo install minikube-linux-amd64 /usr/local/bin/minikube"
    echo "  Windows: choco install minikube"
    echo ""
    exit 1
fi

# Configuration
CPUS=${MINIKUBE_CPUS:-4}
MEMORY=${MINIKUBE_MEMORY:-8192}
DISK=${MINIKUBE_DISK:-50g}
DRIVER=${MINIKUBE_DRIVER:-docker}

echo "Configuration:"
echo "  CPUs:   $CPUS"
echo "  Memory: ${MEMORY}MB"
echo "  Disk:   $DISK"
echo "  Driver: $DRIVER"
echo ""

# Check if cluster already exists
if minikube status &> /dev/null; then
    echo "⚠️  Minikube cluster already exists."
    read -p "Do you want to delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing cluster..."
        minikube delete
    else
        echo "Keeping existing cluster."
        echo "Starting cluster if stopped..."
        minikube start
        exit 0
    fi
fi

echo "Creating Minikube cluster..."
minikube start \
    --cpus=$CPUS \
    --memory=$MEMORY \
    --disk-size=$DISK \
    --driver=$DRIVER

echo ""
echo "✓ Cluster created successfully!"
echo ""

# Enable addons
echo "Enabling metrics-server addon for HPA..."
minikube addons enable metrics-server

echo ""
echo "✓ Metrics server enabled!"
echo ""

# Display cluster info
echo "=========================================="
echo "Cluster Information"
echo "=========================================="
kubectl cluster-info
echo ""
kubectl get nodes
echo ""

echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Start tunnel for LoadBalancer services:"
echo "   minikube tunnel"
echo "   (Run this in a separate terminal and keep it running)"
echo ""
echo "2. Continue with deployment:"
echo "   cd .devops/kube"
echo "   ./03-update-secrets.sh"
echo ""
