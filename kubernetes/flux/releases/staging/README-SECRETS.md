# Staging Environment Secrets

This document describes the Kubernetes Secrets required for the staging environment deployments.

## Required Secrets

All secrets must be created in the `antigravity-staging` namespace **before** deploying the HelmReleases.

### 1. Odoo Database Secret

**Secret Name:** `staging-odoo-db-secret`  
**Namespace:** `antigravity-staging`  
**Required Keys:**
- `password` - Database password for Odoo user

**Creation Command:**
```bash
kubectl create secret generic staging-odoo-db-secret \
  --from-literal=password='<SECURE_PASSWORD>' \
  -n antigravity-staging
```

**Referenced In:** `odoo.yaml`

---

### 2. pgAdmin Secret

**Secret Name:** `staging-pgadmin-secret`  
**Namespace:** `antigravity-staging`  
**Required Keys:**
- `password` - Admin password for pgAdmin interface

**Creation Command:**
```bash
kubectl create secret generic staging-pgadmin-secret \
  --from-literal=password='<SECURE_PASSWORD>' \
  -n antigravity-staging
```

**Referenced In:** `others.yaml`

---

### 3. Grafana Database Secret

**Secret Name:** `staging-grafana-db-secret`  
**Namespace:** `antigravity-staging`  
**Required Keys:**
- `password` - Database password for Grafana database user

**Creation Command:**
```bash
kubectl create secret generic staging-grafana-db-secret \
  --from-literal=password='<SECURE_PASSWORD>' \
  -n antigravity-staging
```

**Referenced In:** `others.yaml`

---

### 4. n8n Database Secret

**Secret Name:** `staging-n8n-db-secret`  
**Namespace:** `antigravity-staging`  
**Required Keys:**
- `password` - Database password for n8n database user

**Creation Command:**
```bash
kubectl create secret generic staging-n8n-db-secret \
  --from-literal=password='<SECURE_PASSWORD>' \
  -n antigravity-staging
```

**Referenced In:** `n8n.yaml`

---

## Security Best Practices

### Option 1: Manual Secret Creation (Development/Staging)

For development and staging environments, you can create secrets manually using `kubectl`:

```bash
# Generate a secure random password
openssl rand -base64 32

# Create the secret
kubectl create secret generic <secret-name> \
  --from-literal=password='<generated-password>' \
  -n antigravity-staging
```

### Option 2: Sealed Secrets (Recommended for GitOps)

Install [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) to encrypt secrets that can be safely committed to Git:

```bash
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create a sealed secret
echo -n '<password>' | kubectl create secret generic staging-odoo-db-secret \
  --dry-run=client \
  --from-file=password=/dev/stdin \
  -o yaml \
  -n antigravity-staging | \
  kubeseal -o yaml > staging-odoo-db-sealed-secret.yaml

# Commit the sealed secret to Git
git add staging-odoo-db-sealed-secret.yaml
```

### Option 3: External Secrets Operator (Recommended for Production)

Use [External Secrets Operator](https://external-secrets.io/) to integrate with:
- AWS Secrets Manager
- Azure Key Vault
- Google Secret Manager
- HashiCorp Vault
- etc.

Example ExternalSecret manifest:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: staging-odoo-db-secret
  namespace: antigravity-staging
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: staging-odoo-db-secret
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: staging/odoo/database
        property: password
```

### Option 4: SOPS (Mozilla's Secrets OPerationS)

Encrypt secrets in Git using [SOPS](https://github.com/mozilla/sops):

```bash
# Encrypt a secret file
sops -e secrets.yaml > secrets.enc.yaml

# Decrypt and apply
sops -d secrets.enc.yaml | kubectl apply -f -
```

---

## Verification

After creating secrets, verify they exist:

```bash
# List all secrets in staging namespace
kubectl get secrets -n antigravity-staging

# Verify a specific secret exists and has the correct keys
kubectl get secret staging-odoo-db-secret -n antigravity-staging -o jsonpath='{.data}' | jq 'keys'
```

---

## Important Notes

⚠️ **NEVER commit plaintext secrets to Git**

⚠️ **Rotate secrets regularly** - especially after team member changes

⚠️ **Use strong, randomly-generated passwords** for all environments

⚠️ **Restrict access** to the namespace where secrets are stored using RBAC

---

## Troubleshooting

### HelmRelease fails with "secret not found"

Ensure the secret exists in the correct namespace:
```bash
kubectl get secret <secret-name> -n antigravity-staging
```

### Helm chart doesn't support secretRef

If your Helm chart doesn't natively support `passwordSecretRef`, you may need to:
1. Update the chart templates to use `valueFrom.secretKeyRef`
2. Use Helm's `lookup` function to fetch secret values
3. Modify the chart to accept external secrets

---

## Contact

For questions about secret management in this project, please contact the DevOps team or refer to the main project documentation.
