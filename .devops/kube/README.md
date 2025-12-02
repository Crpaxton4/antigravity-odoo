# DevOps Scripts - Kubernetes Deployment

Automated scripts for deploying the Antigravity Odoo stack to Kubernetes.

## Prerequisites

Install required tools:

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Minikube (for local deployment)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

## Quick Start

Run scripts in order:

```bash
cd .devops/kube

# 1. Setup Minikube cluster
./02-setup-cluster.sh

# 2. Start tunnel (in separate terminal)
minikube tunnel

# 3. Update secrets
./03-update-secrets.sh

# 4. Update Git repository URL
./04-update-git-repo.sh

# 5. Install Flux CD
./05-install-flux.sh

# 6. Deploy all services
./06-deploy.sh

# 7. Get service URLs
./07-access-services.sh

# 8. Check health
./08-health-check.sh
```

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `02-setup-cluster.sh` | Create and configure Minikube cluster |
| `03-update-secrets.sh` | Generate/update passwords in HelmReleases |
| `04-update-git-repo.sh` | Update Git repository URL in Flux source |
| `05-install-flux.sh` | Install Flux CD components |
| `06-deploy.sh` | Deploy all services via Flux |
| `07-access-services.sh` | Get service access URLs |
| `08-health-check.sh` | Check deployment health and status |
| `09-cleanup.sh` | Delete all resources and cluster |

## Environment Variables

Configure Minikube resources:

```bash
export MINIKUBE_CPUS=4
export MINIKUBE_MEMORY=8192
export MINIKUBE_DISK=50g
export MINIKUBE_DRIVER=docker

./02-setup-cluster.sh
```

## Monitoring

### Watch deployment progress
```bash
# Watch pods
kubectl get pods -n antigravity-dev -w

# Watch Flux
flux logs --follow

# Watch HelmReleases
watch flux get helmreleases -n antigravity-dev
```

### Check resource usage
```bash
kubectl top nodes
kubectl top pods -n antigravity-dev
```

## Troubleshooting

### Pods not starting
```bash
kubectl get pods -n antigravity-dev
kubectl describe pod <pod-name> -n antigravity-dev
kubectl logs <pod-name> -n antigravity-dev
```

### Flux issues
```bash
flux check
flux logs --all-namespaces
```

### HelmRelease stuck
```bash
kubectl describe helmrelease <release-name> -n antigravity-dev
flux reconcile helmrelease <release-name> -n antigravity-dev
```

## Cleanup

```bash
# Delete everything
./09-cleanup.sh

# Or manually
kubectl delete namespace antigravity-dev
flux uninstall
minikube delete
```

## Multi-Environment

Create additional environments:

```bash
# Create staging environment
cd ../../kubernetes/scripts
./create-environment.sh staging

# Deploy staging
kubectl create namespace antigravity-staging
kubectl apply -f ../../kubernetes/flux/releases/staging/
```

## Security Notes

- **Secrets**: Auto-generated passwords are saved to `.secrets.txt`
- **Git**: Never commit `.secrets.txt` or `*.bak` files (already in .gitignore)
- **Production**: Use Sealed Secrets or External Secrets Operator

## Additional Resources

- [Main Documentation](../../kubernetes/README.md)
- [Flux Guide](../../kubernetes/docs/flux-guide.md)
- [Quick Reference](../../kubernetes/QUICK_REFERENCE.md)
