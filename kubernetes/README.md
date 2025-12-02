# Kubernetes Deployment Guide

This directory contains production-ready Kubernetes manifests for deploying the Antigravity Odoo stack.

## Architecture

The stack includes:
- **PostgreSQL** (pgvector) - Consolidated database for all services
- **Odoo 19.0** - ERP system with autoscaling (1-5 replicas)
- **n8n** - Workflow automation with autoscaling (1-3 replicas)
- **Ollama** - Local LLM
- **pgAdmin** - Database administration
- **Monitoring Stack** - Prometheus, Grafana, exporters

## Technology Stack

- **Kubernetes** - Container orchestration
- **Helm 3** - Package management and templating
- **Flux CD** - GitOps continuous delivery
- **Horizontal Pod Autoscaler** - Automatic scaling
- **Persistent Volumes** - Data persistence

## Prerequisites

### Required Tools

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Helm 3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Flux CLI
brew install fluxcd/tap/flux
# or: curl -s https://fluxcd.io/install.sh | sudo bash
```

### Kubernetes Cluster

**Option 1: Minikube (Local Development)**
```bash
# Install Minikube
brew install minikube

# Start cluster with sufficient resources
minikube start --cpus=4 --memory=8192 --disk-size=50g

# Enable metrics server for HPA
minikube addons enable metrics-server

# Enable tunneling for LoadBalancer services
minikube tunnel  # Run in separate terminal
```

**Option 2: Multi-Node Cluster (Testing/Production)**
```bash
# Using kind (Kubernetes in Docker)
kind create cluster --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF
```

## Quick Start

### 1. Install Flux CD

```bash
cd kubernetes
./scripts/install-flux.sh
```

### 2. Create Namespace

```bash
kubectl create namespace antigravity-dev
```

### 3. Update Secrets

Edit `kubernetes/flux/releases/dev/*.yaml` and replace all `changeme` passwords:

```yaml
values:
  postgresql:
    postgresPassword: "YOUR_SECURE_PASSWORD"  # Replace this
    adminPassword: "YOUR_ADMIN_PASSWORD"      # Replace this
```

**IMPORTANT**: For production, use **Sealed Secrets** or external secret management.

### 4. Deploy GitRepository Source

```bash
# Update the Git URL in gitrepository.yaml first
kubectl apply -f flux/sources/gitrepository.yaml
```

### 5. Deploy Services

```bash
# Deploy all services to dev environment
kubectl apply -f flux/releases/dev/

# Watch deployment
flux get helmreleases -n antigravity-dev
kubectl get pods -n antigravity-dev -w
```

### 6. Access Services

```bash
# Get LoadBalancer IPs (Minikube uses minikube tunnel)
kubectl get svc -n antigravity-dev

# Access services:
# - Odoo: http://<ODOO-EXTERNAL-IP>:8069
# - n8n: http://<N8N-EXTERNAL-IP>:5678
# - Grafana: http://<GRAFANA-EXTERNAL-IP>:3000
# - pgAdmin: http://<PGADMIN-EXTERNAL-IP>:80
# - Prometheus: http://<PROMETHEUS-EXTERNAL-IP>:9090
```

## Helm Charts

Each service has its own Helm chart in `helm/`:

- [`helm/postgresql/`](helm/postgresql/) - StatefulSet with multi-replica support
- [`helm/odoo/`](helm/odoo/) - Deployment with HPA (1-5 replicas)
- [`helm/n8n/`](helm/n8n/) - Deployment with HPA (1-3 replicas)
- [`helm/ollama/`](helm/ollama/) - Deployment for LLM
- [`helm/pgadmin/`](helm/pgadmin/) - Single replica admin interface
- [`helm/monitoring/`](helm/monitoring/) - Prometheus, Grafana, exporters

### Testing Charts Locally

```bash
# Lint charts
helm lint helm/postgresql
helm lint helm/odoo

# Template and preview
helm template odoo ./helm/odoo --values ./helm/odoo/values.yaml

# Install directly (without Flux)
helm install postgresql ./helm/postgresql \
  --namespace antigravity-dev \
  --values ./helm/postgresql/values.yaml
```

## Environments

The stack supports multiple environments via Helm values:

- `values.yaml` - **Dev** environment (default)
- `values-staging.yaml` - **Staging** environment
- `values-production.yaml` - **Production** environment

### Creating On-Demand Environments

```bash
# Create a new environment for feature development
./scripts/create-environment.sh feature-auth

# This creates:
# - New namespace: antigravity-feature-auth
# - HelmRelease manifests in flux/releases/feature-auth/

# Deploy the environment
kubectl apply -f flux/releases/feature-auth/

# Delete when done
kubectl delete namespace antigravity-feature-auth
rm -rf flux/releases/feature-auth/
```

## GitOps Workflow

Flux automatically reconciles changes from Git:

1. **Make changes** to Helm charts or HelmRelease manifests
2. **Commit and push** to Git
3. **Flux detects** changes within 1 minute
4. **Automatic deployment** to cluster

```bash
# Monitor Flux
flux get sources git
flux get helmreleases -A

# View logs
flux logs --follow

# Force reconciliation
flux reconcile source git antigravity-odoo
flux reconcile helmrelease odoo -n antigravity-dev
```

## Autoscaling

Services automatically scale based on CPU/memory:

| Service | Min Replicas | Max Replicas | Trigger |
|---------|--------------|--------------|---------|
| Odoo    | 1            | 5            | 70% CPU |
| n8n     | 1            | 3            | 70% CPU |
| Grafana | 1            | 2            | 80% CPU |

```bash
# Watch autoscaling
kubectl get hpa -n antigravity-dev -w

# View current resource usage
kubectl top pods -n antigravity-dev
```

## Persistence

All data is stored in Persistent Volumes:

| Service    | Volume Size (Dev) | Volume Size (Prod) |
|------------|-------------------|---------------------|
| PostgreSQL | 10Gi              | 100Gi               |
| Odoo       | 10Gi              | 100Gi               |
| n8n        | 5Gi               | 50Gi                |
| Ollama     | 50Gi              | 200Gi               |
| Prometheus | 20Gi              | 100Gi               |
| Grafana    | 5Gi               | 20Gi                |

```bash
# List persistent volumes
kubectl get pv
kubectl get pvc -n antigravity-dev

# Check volume usage
kubectl exec -n antigravity-dev postgresql-0 -- df -h /var/lib/postgresql/data
```

## Multi-Node Support

The manifests include pod anti-affinity for distribution across nodes:

- **PostgreSQL**: Replicas spread across different nodes (production: 3 replicas)
- **Odoo**: Preferred anti-affinity (soft constraint)
- **n8n**: Preferred anti-affinity

```bash
# View pod distribution
kubectl get pods -n antigravity-dev -o wide

# Test node failure
kubectl drain <node-name> --ignore-daemonsets
# Pods automatically reschedule to other nodes

# Re-enable node
kubectl uncordon <node-name>
```

## Monitoring

### Prometheus

Automatically collects metrics from:
- PostgreSQL (via postgres-exporter)
- Containers (via cAdvisor)
- Kubernetes (via kube-state-metrics)

### Grafana

Import community dashboards:
1. Access Grafana UI
2. Navigate to Dashboards → Import
3. Import by ID:
   - **9628** - PostgreSQL Database
   - **14282** - Container Monitoring (cAdvisor)
   - **1860** - Node Exporter

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n antigravity-dev

# View pod logs
kubectl logs -n antigravity-dev <pod-name>

# Describe pod for events
kubectl describe pod -n antigravity-dev <pod-name>
```

### Flux Not Reconciling

```bash
# Check Flux status
flux check

# View Flux logs
flux logs --all-namespaces

# Suspend and resume
flux suspend helmrelease odoo -n antigravity-dev
flux resume helmrelease odoo -n antigravity-dev
```

### Database Connection Issues

```bash
# Test PostgreSQL connectivity
kubectl run -it --rm debug --image=postgres:16 --restart=Never -- \
  psql -h postgresql.antigravity-dev -U odoo_user -d odoo_db

# Check PostgreSQL logs
kubectl logs -n antigravity-dev postgresql-0
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n antigravity-dev

# Check events for volume issues
kubectl get events -n antigravity-dev --sort-by='.lastTimestamp'
```

## Security Best Practices

### Secrets Management

**Development**: Secrets in HelmRelease values (acceptable for dev)  
**Production**: Use **Sealed Secrets** or External Secrets Operator

```bash
# Install Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create sealed secret
echo -n "my-password" | kubectl create secret generic my-secret \
  --dry-run=client --from-file=password=/dev/stdin -o yaml | \
  kubeseal -o yaml > sealed-secret.yaml
```

### Network Policies

Apply network policies to restrict pod-to-pod communication:

```bash
kubectl apply -f helm/postgresql/templates/networkpolicy.yaml
```

### RBAC

Review and customize service account permissions in each Helm chart.

## Production Deployment Checklist

- [ ] Update all passwords/secrets
- [ ] Configure backup strategy for PostgreSQL
- [ ] Set up SSL/TLS with cert-manager and Ingress
- [ ] Configure resource limits based on load testing
- [ ] Enable Pod Security Policies
- [ ] Set up monitoring alerts in Prometheus/AlertManager
- [ ] Configure log aggregation (e.g., ELK, Loki)
- [ ] Test disaster recovery procedures
- [ ] Document runbooks for common operations
- [ ] Set up CI/CD pipeline for Git changes

## Additional Resources

- [Flux Documentation](https://fluxcd.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

## Support

For issues or questions:
1. Check logs: `kubectl logs` and `flux logs`
2. Review events: `kubectl get events`
3. Consult documentation in `kubernetes/docs/`
