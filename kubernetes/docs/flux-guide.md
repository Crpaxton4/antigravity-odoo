# Flux CD Guide

This guide explains how to use Flux CD for GitOps deployments of the Antigravity Odoo stack.

## What is Flux?

Flux is a GitOps tool that automatically synchronizes your Kubernetes cluster with a Git repository. When you push changes to Git, Flux detects them and applies them to your cluster.

## Key Concepts

### GitRepository
Defines the Git repository source:
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: antigravity-odoo
spec:
  interval: 1m0s  # Check for changes every minute
  url: https://github.com/YOUR_USERNAME/antigravity-odoo
  ref:
    branch: main
```

### HelmRelease
Defines a Helm chart deployment:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: odoo
spec:
  interval: 5m      # Reconcile every 5 minutes
  chart:
    spec:
      chart: ./kubernetes/helm/odoo
      sourceRef:
        kind: GitRepository
        name: antigravity-odoo
  values:
    replicaCount: 2  # Override default values
```

## Installation

### Method 1: Manual Install (Development)

```bash
# Install Flux components
flux install

# Create source
kubectl apply -f kubernetes/flux/sources/gitrepository.yaml

# Deploy services
kubectl apply -f kubernetes/flux/releases/dev/
```

### Method 2: Bootstrap (Production - Recommended)

Bootstrap connects Flux directly to your Git repository:

```bash
# Bootstrap Flux with GitHub
flux bootstrap github \
  --owner=YOUR_USERNAME \
  --repository=antigravity-odoo \
  --branch=main \
  --path=./kubernetes/flux \
  --personal \
  --token-auth

# Or with GitLab
flux bootstrap gitlab \
  --owner=YOUR_USERNAME \
  --repository=antigravity-odoo \
  --branch=main \
  --path=./kubernetes/flux \
  --token-auth
```

**Benefits of Bootstrap**:
- Flux manages itself via Git
- Automatic self-healing
- Complete GitOps workflow
- Easy updates and rollbacks

## Common Operations

### View Resources

```bash
# List Git sources
flux get sources git

# List Helm releases (all namespaces)
flux get helmreleases -A

# Check Flux status
flux check
```

### Manual Reconciliation

```bash
# Force update from Git
flux reconcile source git antigravity-odoo

# Force Helm release update
flux reconcile helmrelease odoo -n antigravity-dev

# Reconcile all
flux reconcile helmrelease --all
```

### Suspend/Resume

```bash
# Suspend automatic reconciliation
flux suspend helmrelease odoo -n antigravity-dev

# Resume
flux resume helmrelease odoo -n antigravity-dev
```

### View Logs

```bash
# All Flux logs
flux logs --all-namespaces --follow

# Specific controller
flux logs --kind=HelmRelease --name=odoo --namespace=antigravity-dev
```

## Making Changes
### Option 1: Update Values in HelmRelease

1. Edit `kubernetes/flux/releases/dev/odoo.yaml`:
```yaml
spec:
  values:
    replicaCount: 3  # Change from 2 to 3
```

2. Commit and push:
```bash
git add kubernetes/flux/releases/dev/odoo.yaml
git commit -m "Scale Odoo to 3 replicas"
git push
```

3. Watch Flux apply changes:
```bash
flux reconcile source git antigravity-odoo
flux get helmreleases -n antigravity-dev
```

### Option 2: Update Helm Chart

1. Edit `kubernetes/helm/odoo/values.yaml`
2. Commit and push
3. Flux automatically redeploys

## Handling Dependencies

HelmReleases can depend on each other:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: odoo
spec:
  dependsOn:
    - name: postgresql
      namespace: antigravity-dev
```

Flux waits for PostgreSQL to be ready before deploying Odoo.

## Secrets Management

### Option 1: SOPS (Recommended for Production)

Encrypt secrets in Git:

```bash
# Install SOPS
brew install sops

# Create GPG key
gpg --gen-key

# Encrypt secret
sops --encrypt --pgp YOUR_KEY_ID secret.yaml > secret.enc.yaml

# Configure Flux to decrypt
flux create secret gpg sops-gpg \
  --from-file=sops.asc=/path/to/private.key \
  --namespace=flux-system
```

### Option 2: Sealed Secrets

```bash
# Install sealed-secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Seal a secret
echo -n "password" | kubectl create secret generic db-password \
  --dry-run=client --from-file=password=/dev/stdin -o yaml | \
  kubeseal -o yaml > sealed-secret.yaml

# Commit sealed-secret.yaml to Git (it's encrypted)
```

## Multi-Environment Strategy

### Separate Namespaces

```
kubernetes/flux/releases/
├── dev/
│   ├── postgresql.yaml
│   └── odoo.yaml
├── staging/
│   ├── postgresql.yaml  # Different values
│   └── odoo.yaml
└── production/
    ├── postgresql.yaml  # Production values
    └── odoo.yaml
```

### Environment-Specific Values

```yaml
# dev/odoo.yaml
spec:
  values:
    replicaCount: 1
    odoo:
      debug:
        enabled: true

# production/odoo.yaml
spec:
  values:
    replicaCount: 5
    odoo:
      debug:
        enabled: false
```

## Rollback

### Automatic Rollback

Flux has built-in health checks. If a deployment fails, it marks it as "not ready."

### Manual Rollback

```bash
# Revert Git commit
git revert HEAD
git push

# Or force reconcile to specific commit
flux reconcile source git antigravity-odoo --with-source-revision=main/abc123
```

## Monitoring Flux

### Prometheus Metrics

Flux exports Prometheus metrics:
- `gotk_reconcile_condition` - Reconciliation status
- `gotk_reconcile_duration_seconds` - Reconciliation duration

### Alerts

Set up Prometheus alerts for Flux failures:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta1
kind: Alert
metadata:
  name: on-call-webapp
  namespace: flux-system
spec:
  providerRef:
    name: on-call
  eventSeverity: error
  eventSources:
    - kind: HelmRelease
      name: '*'
```

## Troubleshooting

### HelmRelease Stuck

```bash
# Check HelmRelease status
kubectl describe helmrelease odoo -n antigravity-dev

# Check Helm release directly
helm list -n antigravity-dev
helm history odoo -n antigravity-dev

# Force uninstall and let Flux reinstall
flux suspend helmrelease odoo -n antigravity-dev
helm uninstall odoo -n antigravity-dev
flux resume helmrelease odoo -n antigravity-dev
```

### Git Source Failing

```bash
# Check GitRepository status
kubectl describe gitrepository antigravity-odoo -n flux-system

# Common issues:
# - Wrong URL
# - Missing credentials (for private repos)
# - Branch doesn't exist
```

### Image Pull Errors

```bash
# Create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n antigravity-dev

# Reference in HelmRelease
spec:
  values:
    imagePullSecrets:
      - name: regcred
```

## Best Practices

1. **Use Bootstrap**: Connect Flux to Git for full GitOps
2. **Encrypt Secrets**: Never commit plain secrets
3. **Pin Versions**: Use specific image tags, not `latest`
4. **Health Checks**: Define proper readiness/liveness probes
5. **Dependencies**: Use `dependsOn` for deployment order
6. **Namespaces**: Separate environments by namespace
7. **RBAC**: Limit Flux permissions per namespace
8. **Monitoring**: Watch Flux metrics and set up alerts

## Additional Resources

- [Official Flux Documentation](https://fluxcd.io/docs/)
- [Flux CLI Reference](https://fluxcd.io/flux/cmd/)
- [GitOps Toolkit](https://toolkit.fluxcd.io/)
- [Examples Repository](https://github.com/fluxcd/flux2-kustomize-helmexample)
