# Kubernetes Dashboard

This directory contains the Flux CD configuration for the Kubernetes Dashboard, following Kubernetes best practices for managing external Helm chart dependencies.

## Architecture

The dashboard is deployed using Flux CD's **HelmRepository + HelmRelease** pattern:

1. **HelmRepository** (`repositories/kubernetes-dashboard.yaml`)
   - Points to the official Kubernetes Dashboard Helm chart repository
   - Syncs every 1 hour to check for updates

2. **HelmRelease** (`infrastructure/kubernetes-dashboard.yaml`)
   - Declaratively defines the desired dashboard configuration
   - Uses version pinning `>=7.0.0 <8.0.0` for stability
   - Automatic remediation with 3 retries on failures

3. **RBAC** (`infrastructure/dashboard-rbac.yaml`)
   - ServiceAccount with cluster-admin privileges for full access
   - ClusterRoleBinding for authorization
   - Secret to hold the bearer token for authentication

## Security Configuration

The dashboard is configured with:

- **ClusterIP service** - Not exposed externally by default
- **Token-based authentication** - Secure bearer token login
- **Admin ServiceAccount** - Full cluster access for development
- **HTTPS enabled** - Encrypted communication

## Access Dashboard

### Quick Access
```bash
# Run the access script (handles everything)
./.devops/kube/13-access-dashboard.sh
```

### Manual Access

1. Get the bearer token:
```bash
kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 --decode
```

2. Start kubectl proxy:
```bash
kubectl proxy
```

3. Open in browser:
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

4. Login with the bearer token from step 1

## Configuration

The dashboard is configured via Helm values in `infrastructure/kubernetes-dashboard.yaml`:

- **Skip login**: Enabled for development convenience
- **System banner**: "Antigravity Development Cluster"
- **Metrics scraper**: Enabled for resource monitoring
- **Resource limits**: CPU 200m, Memory 256Mi
- **Auto-refresh**: Every 5 seconds

## Deployment

The dashboard is automatically deployed when you run:

```bash
./.devops/kube/06-deploy.sh
# or
./.devops/kube/01-deploy-all.sh
```

## Removal

To remove the manually installed dashboard (if any):

```bash
# Uninstall Helm release
helm uninstall kubernetes-dashboard -n kubernetes-dashboard

# Delete namespace
kubectl delete namespace kubernetes-dashboard
```

The Flux-managed dashboard will be deployed automatically on next deployment.

## Troubleshooting

### Dashboard not accessible
```bash
# Check if dashboard is running
kubectl get pods -n kubernetes-dashboard

# Check logs
kubectl logs -l app.kubernetes.io/name=kubernetes-dashboard -n kubernetes-dashboard

# Check HelmRelease status
flux get helmreleases -n flux-system
```

### Token not working
```bash
# Verify secret exists
kubectl get secret admin-user-token -n kubernetes-dashboard

# Recreate RBAC
kubectl apply -f kubernetes/flux/infrastructure/dashboard-rbac.yaml
```

### Dashboard pod crashlooping
```bash
# Check events
kubectl describe pod -l app.kubernetes.io/name=kubernetes-dashboard -n kubernetes-dashboard

# Check HelmRelease
kubectl describe helmrelease kubernetes-dashboard -n flux-system
```

## Best Practices Implemented

✅ **External Dependency Management** - Using HelmRepository instead of vendoring charts  
✅ **Version Pinning** - Lock to major version, allow minor/patch updates  
✅ **Namespace Isolation** - Dedicated `kubernetes-dashboard` namespace  
✅ **RBAC** - Proper ServiceAccount with token-based auth  
✅ **GitOps** - All configuration in Git, managed by Flux  
✅ **Remediation** - Automatic retry on failures  
✅ **Resource Limits** - Prevent resource exhaustion  

## Production Considerations

For production deployments, consider:

1. **Disable skip-login** - Require authentication
2. **Use Ingress** - With TLS termination
3. **Restrict RBAC** - Use read-only roles instead of cluster-admin
4. **Enable audit logging** - Track access
5. **Network policies** - Restrict dashboard network access
