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

# Check if cluster already exists and is running
if minikube status &> /dev/null; then
    CLUSTER_STATUS=$(minikube status -o json 2>/dev/null | grep -o '"Running"' | wc -l)
    
    if [ "$CLUSTER_STATUS" -ge 3 ]; then
        echo "✓ Minikube cluster is already running"
        
        # Check if it matches desired configuration
        # Retrieve CPU capacity with proper error handling
        if CURRENT_CPUS=$(kubectl get node minikube -o jsonpath='{.status.capacity.cpu}' 2>/dev/null); then
            # Validate numeric value
            if ! [[ "$CURRENT_CPUS" =~ ^[0-9]+$ ]]; then
                echo "⚠️  Warning: Retrieved non-numeric CPU value, defaulting to 0" >&2
                CURRENT_CPUS=0
            fi
        else
            echo "⚠️  Warning: Failed to retrieve CPU capacity (kubectl error or cluster unreachable), defaulting to 0" >&2
            CURRENT_CPUS=0
        fi
        
        # Retrieve memory capacity with proper error handling
        if CURRENT_MEMORY_RAW=$(kubectl get node minikube -o jsonpath='{.status.capacity.memory}' 2>/dev/null); then
            # Strip Ki suffix and validate
            CURRENT_MEMORY="${CURRENT_MEMORY_RAW//Ki/}"
            if [[ "$CURRENT_MEMORY" =~ ^[0-9]+$ ]]; then
                CURRENT_MEMORY_MB=$((CURRENT_MEMORY / 1024))
            else
                echo "⚠️  Warning: Retrieved non-numeric memory value, defaulting to 0" >&2
                CURRENT_MEMORY_MB=0
            fi
        else
            echo "⚠️  Warning: Failed to retrieve memory capacity (kubectl error or cluster unreachable), defaulting to 0" >&2
            CURRENT_MEMORY_MB=0
        fi
        
        echo ""
        echo "Current cluster configuration:"
        echo "  CPUs:   $CURRENT_CPUS"
        echo "  Memory: ${CURRENT_MEMORY_MB}MB"
        echo ""
        
        if [ "$1" != "--force" ]; then
            read -p "Do you want to delete and recreate? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Keeping existing cluster."
                exit 0
            fi
        fi
        
        echo "Deleting existing cluster..."
        minikube delete
    else
        echo "⚠️  Minikube cluster exists but is not fully running."
        echo "Deleting and recreating..."
        minikube delete
    fi
elif minikube profile list 2>/dev/null | grep -q minikube; then
    echo "⚠️  Minikube cluster exists but is stopped."
    
    if [ "$1" != "--force" ]; then
        read -p "Do you want to start the existing cluster? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "Starting existing cluster..."
            minikube start
            exit 0
        fi
    fi
    
    echo "Deleting stopped cluster..."
    minikube delete
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
echo "   ./.devops/kube/03-update-secrets.sh"
echo ""
