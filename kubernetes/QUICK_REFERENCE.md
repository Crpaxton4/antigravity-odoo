# Quick Reference - Kubernetes Commands

## Essential Commands

### Cluster Info
```bash
kubectl cluster-info
kubectl get nodes
kubectl top nodes
```

### View Resources
```bash
# All resources in namespace
kubectl get all -n antigravity-dev

# Pods
kubectl get pods -n antigravity-dev -o wide

# Services
kubectl get svc -n antigravity-dev

# PersistentVolumeClaims
kubectl get pvc -n antigravity-dev

# HorizontalPodAutoscalers
kubectl get hpa -n antigravity-dev
```

### Logs and Debugging
```bash
# Pod logs
kubectl logs -f <pod-name> -n antigravity-dev

# Previous container logs (if crashed)
kubectl logs <pod-name> --previous -n antigravity-dev

# Describe resource
kubectl describe pod <pod-name> -n antigravity-dev

# Execute command in pod
kubectl exec -it <pod-name> -n antigravity-dev -- /bin/bash

# Port forward
kubectl port-forward svc/odoo 8069:8069 -n antigravity-dev
```

### Flux Commands
```bash
# Check Flux status
flux check

# List sources
flux get sources git

# List HelmReleases
flux get helmreleases -A

# Reconcile immediately
flux reconcile source git antigravity-odoo
flux reconcile helmrelease odoo -n antigravity-dev

# Suspend/Resume
flux suspend helmrelease odoo -n antigravity-dev
flux resume helmrelease odoo -n antigravity-dev

# View logs
flux logs --all-namespaces --follow
```

### Helm Commands
```bash
# List releases
helm list -n antigravity-dev

# Get values
helm get values postgresql -n antigravity-dev

# History
helm history odoo -n antigravity-dev

# Rollback
helm rollback odoo 1 -n antigravity-dev
```

## Deployment Workflow

### Initial Setup
```bash
# 1. Start Minikube
minikube start --cpus=4 --memory=8192 --disk-size=50g
minikube addons enable metrics-server
minikube tunnel  # Separate terminal

# 2. Install Flux
cd kubernetes
./scripts/install-flux.sh

# 3. Create namespace
kubectl create namespace antigravity-dev

# 4. Apply sources
kubectl apply -f flux/sources/gitrepository.yaml

# 5. Deploy services
kubectl apply -f flux/releases/dev/

# 6. Watch deployment
flux get helmreleases -n antigravity-dev
kubectl get pods -n antigravity-dev -w
```

### Making Changes
```bash
# Edit HelmRelease values
vim flux/releases/dev/odoo.yaml

# Commit and push
git add flux/releases/dev/odoo.yaml
git commit -m "Update Odoo configuration"
git push

# Force reconcile (optional, happens automatically within 1min)
flux reconcile source git antigravity-odoo
```

### Scaling
```bash
# Manual scale
kubectl scale deployment odoo --replicas=3 -n antigravity-dev

# View HPA
kubectl get hpa odoo -n antigravity-dev

# Describe HPA
kubectl describe hpa odoo -n antigravity-dev
```

### Troubleshooting
```bash
# Pod not starting
kubectl describe pod <pod-name> -n antigravity-dev
kubectl logs <pod-name> -n antigravity-dev

# HelmRelease failing
kubectl describe helmrelease odoo -n antigravity-dev
flux logs --kind=HelmRelease --name=odoo -n antigravity-dev

# Database connection test
kubectl run -it --rm debug --image=postgres:16 -n antigravity-dev --restart=Never -- \
  psql -h postgresql -U odoo_user -d odoo_db

# Check events
kubectl get events -n antigravity-dev --sort-by='.lastTimestamp'
```

## Cleanup
```bash
# Delete namespace (removes everything)
kubectl delete namespace antigravity-dev

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

##Service Access (Minikube)

```bash
# Get service URLs
minikube service odoo -n antigravity-dev --url
minikube service n8n -n antigravity-dev --url
minikube service grafana -n antigravity-dev --url

# Or with kubectl
kubectl get svc -n antigravity-dev
```

## Performance Monitoring
```bash
# Resource usage
kubectl top pods -n antigravity-dev
kubectl top nodes

# Watch resources
watch kubectl top pods -n antigravity-dev

# Prometheus queries (via port-forward)
kubectl port-forward svc/prometheus 9090:9090 -n antigravity-dev
# Open: http://localhost:9090
```
