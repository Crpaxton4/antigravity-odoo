# Database Credentials Migration

## Overview

Database credentials (`db_user` and `db_password`) have been moved from the ConfigMap to a dedicated Secret for improved security.

## Changes Made

### 1. Secret Template (`templates/secret.yaml`)

**New Secret Name:** `{{ include "odoo.fullname" . }}-db-credentials`

The secret now contains:
- `db-user`: Database username
- `db-password`: Database password

Both values are sourced from `.Values.odoo.database.user` and `.Values.odoo.database.password`.

### 2. ConfigMap (`templates/configmap.yaml`)

**Removed sensitive fields:**
- `db_user` - Now retrieved from Secret via environment variable

**Remaining non-sensitive fields:**
- `db_host` - Database hostname
- `db_port` - Database port
- `db_name` - Database name

### 3. Deployment (`templates/deployment.yaml`)

**Updated environment variables:**

```yaml
env:
- name: HOST
  value: {{ .Values.odoo.database.host | quote }}
- name: USER
  valueFrom:
    secretKeyRef:
      name: {{ include "odoo.fullname" . }}-db-credentials
      key: db-user
- name: PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "odoo.fullname" . }}-db-credentials
      key: db-password
- name: DB_NAME
  value: {{ .Values.odoo.database.name | quote }}
```

### 4. Values (`values.yaml`)

**Password Handling (Updated):**

⚠️ **BREAKING CHANGE**: The default hardcoded password has been removed for security.

```yaml
odoo:
  database:
    host: postgresql
    port: 5432
    name: odoo_db
    user: odoo_user
    password: ""  # Must be provided explicitly
    # Optional: Reference an external secret for the database password
    passwordSecretRef:
      name: staging-odoo-db-secret
      key: password
```

**Password is now REQUIRED** - The chart will fail if no password is provided via:
1. `.Values.odoo.database.password` (direct password)
2. `.Values.odoo.database.passwordSecretRef` (external secret reference)
3. `.Values.existingSecret` (existing secret with db-user and db-password keys)

## Usage

### ⚠️ IMPORTANT: Password is Required

The chart **no longer has a default password**. You must explicitly provide credentials using one of the three methods below.

### Option 1: Set Password Directly (Development Only)

**Warning:** Only use this for local development. Not recommended for production.

```bash
helm install odoo ./kubernetes/helm/odoo \
  --set odoo.database.password='your_dev_password' \
  -n development
```

Or in values file:
```yaml
odoo:
  database:
    password: your_dev_password
```

### Option 2: Use External Secret (Production/Staging - RECOMMENDED)

For production and staging environments, reference an external Kubernetes Secret:

1. Create the external secret:

```bash
kubectl create secret generic production-odoo-db-secret \
  --from-literal=password='<SECURE_PASSWORD>' \
  -n antigravity-prod
```

2. Configure the chart to use it:

```yaml
odoo:
  database:
    user: odoo_user
    passwordSecretRef:
      name: production-odoo-db-secret
      key: password
```

3. The chart will:
   - Still create a Secret for `db-user`
   - Reference the external Secret for `db-password`

### Option 3: Use Existing Secret for Everything

Set `existingSecret` to use a pre-created secret for both user and password:

```yaml
existingSecret: my-odoo-db-secret
```

Your secret must contain:
- `db-user` key
- `db-password` key

Example:

```bash
kubectl create secret generic my-odoo-db-secret \
  --from-literal=db-user='odoo_user' \
  --from-literal=db-password='<SECURE_PASSWORD>' \
  -n antigravity-prod
```

## Migration Guide

### For Existing Deployments

⚠️ **BREAKING CHANGE**: If you were relying on the default "changeme" password, your deployment will fail after upgrading.

**Before upgrading:**

1. **Check your current password:**
   ```bash
   kubectl get secret <release-name>-odoo-db-credentials -n <namespace> -o jsonpath='{.data.db-password}' | base64 -d
   ```

2. **Choose your migration path:**

   **Option A: Set password explicitly (quickest for dev)**
   ```bash
   helm upgrade odoo ./kubernetes/helm/odoo \
     --set odoo.database.password='your_password' \
     --reuse-values
   ```

   **Option B: Use external secret (recommended)**
   ```bash
   # Create the secret first
   kubectl create secret generic odoo-db-secret \
     --from-literal=password='your_password' \
     -n <namespace>
   
   # Upgrade with secret reference
   helm upgrade odoo ./kubernetes/helm/odoo \
     --set odoo.database.passwordSecretRef.name=odoo-db-secret \
     --set odoo.database.passwordSecretRef.key=password \
     --reuse-values
   ```

3. **Verify the upgrade:**
   ```bash
   kubectl get pods -n <namespace>
   kubectl logs -n <namespace> <pod-name>
   ```

### For New Deployments

For new deployments, simply use the updated chart with your desired configuration method (Option 1, 2, or 3 above):

```bash
helm install odoo ./kubernetes/helm/odoo \
  --namespace antigravity-dev \
  --create-namespace \
  --values ./kubernetes/helm/odoo/values-production.yaml
```

1. **Verify the secret was created:**

```bash
kubectl get secret -n antigravity-dev | grep db-credentials
```

2. **Verify pods are running correctly:**

```bash
kubectl get pods -n antigravity-dev
kubectl logs -n antigravity-dev <pod-name>
```

## Security Benefits

✅ **Credentials isolated from ConfigMap**: Database credentials are no longer visible in ConfigMaps

✅ **Secret-based access control**: Kubernetes RBAC can restrict access to Secrets separately from ConfigMaps

✅ **Support for external secrets**: Easy integration with external secret management systems

✅ **Audit trail**: Changes to Secrets can be tracked separately from configuration changes

✅ **Encryption at rest**: Secrets can be encrypted at rest in etcd (when enabled in cluster)

## Troubleshooting

### Pod fails to start with authentication error

Check that the secret exists and contains the correct keys:

```bash
kubectl get secret <release-name>-odoo-db-credentials -n <namespace> -o yaml
```

Verify the keys:

```bash
kubectl get secret <release-name>-odoo-db-credentials -n <namespace> -o jsonpath='{.data}' | jq 'keys'
```

Should show: `["db-password", "db-user"]`

### Password not being read from external secret

Verify your `passwordSecretRef` configuration:

```bash
helm get values <release-name> -n <namespace>
```

Check that the referenced secret exists:

```bash
kubectl get secret <secret-name> -n <namespace>
```

### Environment variables not set in pod

Check the pod's environment variables:

```bash
kubectl exec -n <namespace> <pod-name> -- env | grep -E "(USER|PASSWORD|HOST|DB_NAME)"
```

## Related Documentation

- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Helm Secrets Management](https://helm.sh/docs/chart_best_practices/secrets/)
- [External Secrets Operator](https://external-secrets.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)

## Contact

For questions or issues, please contact the DevOps team or open an issue in the project repository.
