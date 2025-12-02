# Antigravity Odoo Stack

A production-ready Odoo 19.0 stack with PostgreSQL (pgvector), n8n, Ollama, and comprehensive monitoring.

## 🚀 Deployment Decision Tree

Choose your deployment path based on your needs:

```mermaid
graph TD
    A[Start] --> B{Environment?}
    B -->|Local Development| C[Docker Compose]
    B -->|Production / Kubernetes| D[Kubernetes + Flux CD]
    
    C --> C1[Quick Start]
    C --> C2[Full Stack]
    
    D --> D1[Local K8s (Minikube)]
    D --> D2[Cloud K8s]
```

| Method | Best For | Tools Required |
|--------|----------|----------------|
| **Docker Compose** | Rapid development, testing, simple deployments | Docker, Docker Compose |
| **Kubernetes (Minikube)** | Testing K8s manifests locally | Minikube, kubectl, Helm, Flux |
| **Kubernetes (Cloud)** | Production, Staging, Scalability | Cloud Provider, kubectl, Helm, Flux |

---

## 🛠️ Technology Stack

- **Core**: Odoo 19.0, PostgreSQL 16 (pgvector), n8n, Ollama
- **Monitoring**: Prometheus, Grafana, cAdvisor, PostgreSQL Exporter, pgAdmin
- **Infrastructure**: Docker, Kubernetes, Helm 3, Flux CD

---

## 🐳 Option 1: Docker Compose (Local Development)

### Prerequisites
- Docker & Docker Compose installed

### Quick Start

1.  **Configure Environment**:
    ```bash
    cp .env.example .env
    # Edit .env with your secure passwords
    ```

2.  **Start Services**:
    ```bash
    docker compose up -d
    ```

3.  **Access Services**:
    - **Odoo**: [http://localhost:8069](http://localhost:8069)
    - **n8n**: [http://localhost:5679](http://localhost:5679)
    - **pgAdmin**: [http://localhost:5050](http://localhost:5050)
    - **Grafana**: [http://localhost:3000](http://localhost:3000)

### Database Access
- **Host**: `postgres` (internal), `localhost` (external if ports mapped)
- **Port**: `5432`
- **Users**:
    - `postgres_admin`: Superuser (renamed from pgadmin)
    - `odoo_user`: Odoo database owner
    - `n8n_user`: n8n database owner

---

## ☸️ Option 2: Kubernetes (Production/Staging)

This stack uses **Flux CD** for GitOps-based deployment and **Helm** for package management.

### Prerequisites
- `kubectl`
- `helm`
- `flux` CLI
- A Kubernetes cluster (Minikube or Cloud)

### 🚀 Quick Start (Automated)

We provide fully automated scripts in `.devops/kube/` for streamlined deployment:

```bash
cd .devops/kube

# Master deployment script (runs all steps)
./01-deploy-all.sh
```

**In a separate terminal, start the tunnel:**
```bash
minikube tunnel
```

That's it! The script will:
1. Setup Minikube cluster
2. Create secrets from `.env` file
3. Update Git repository URL
4. Install Flux CD
5. Deploy all services

### 📦 DevOps Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `01-deploy-all.sh` | **Master script** - Runs full deployment | `./01-deploy-all.sh` |
| `02-setup-cluster.sh` | Creates/manages Minikube cluster | `./02-setup-cluster.sh --force` |
| `00-create-secrets-from-env.sh` | Creates K8s secrets from `.env` | `./00-create-secrets-from-env.sh` |
| `03-update-secrets.sh` | Auto-generates random passwords | `./03-update-secrets.sh` |
| `04-update-git-repo.sh` | Updates Flux Git repository URL | `./04-update-git-repo.sh [url]` |
| `05-install-flux.sh` | Installs Flux CD with verification | `./05-install-flux.sh` |
| `06-deploy.sh` | Deploys all HelmReleases | `./06-deploy.sh` |
| `07-access-services.sh` | Shows service URLs | `./07-access-services.sh` |
| `08-health-check.sh` | Comprehensive health check | `./08-health-check.sh` |
| `09-cleanup.sh` | Tears down deployment | `./09-cleanup.sh` |
| `10-reset-helmreleases.sh` | **Fixes stuck deployments** | `./10-reset-helmreleases.sh dev postgresql` |

### 🔧 Common Operations

**Check deployment health:**
```bash
./.devops/kube/08-health-check.sh
```

**Access services:**
```bash
./.devops/kube/07-access-services.sh
```

**Troubleshoot stuck pods:**
```bash
# Reset a specific service
./.devops/kube/10-reset-helmreleases.sh antigravity-dev postgresql

# Reset all services
./.devops/kube/10-reset-helmreleases.sh antigravity-dev all
```

**Update Helm charts:**
```bash
# 1. Make changes to templates
vim kubernetes/helm/postgresql/templates/statefulset.yaml

# 2. Commit and push
git add .
git commit -m "Update template"
git push

# 3. Reset HelmRelease to apply
./.devops/kube/10-reset-helmreleases.sh antigravity-dev postgresql
```

**Update secrets:**
```bash
# 1. Update .env file
vim .env

# 2. Recreate secrets
./.devops/kube/00-create-secrets-from-env.sh

# 3. Reset affected services
./.devops/kube/10-reset-helmreleases.sh antigravity-dev postgresql
```

### 🎯 Manual Deployment (Advanced)

If you prefer step-by-step control:

1.  **Install Flux**:
    ```bash
    .devops/kube/05-install-flux.sh
    ```

2.  **Create Namespace**:
    ```bash
    kubectl apply -f kubernetes/namespaces.yaml
    ```

3.  **Deploy Services**:
    ```bash
    kubectl apply -f kubernetes/flux/releases/dev/
    ```

### Environments
- **Dev**: `kubernetes/flux/releases/dev/`
- **Staging**: `kubernetes/flux/releases/staging/`
- **Production**: `kubernetes/flux/releases/production/`

To create a new environment:
```bash
kubernetes/scripts/create-environment.sh <env-name>
```

---

## 📊 Monitoring & Observability

### Grafana Dashboards
Login to Grafana (admin/admin by default) and import these dashboards:
- **PostgreSQL**: ID 9628
- **Container Monitoring**: ID 14282
- **Node Exporter**: ID 1860

### Metrics Endpoints
- **Prometheus**: [http://localhost:9090](http://localhost:9090)
- **cAdvisor**: [http://localhost:8080](http://localhost:8080)

---

## 🔒 Security

- **Secrets**: In production, use **Sealed Secrets** or External Secrets Operator. Do not commit raw passwords in Helm values.
- **Network**: Internal services are isolated. Only expose necessary ports.
- **Database**: Service users (odoo, n8n) cannot DROP databases. Only `postgres_admin` has superuser privileges.

---

## 📚 Documentation & References

- [Governance & Contribution](docs/GOVERNANCE.md)
- [Documentation Scheme](docs/DOCUMENTATION_SCHEME.md)
- [n8n Environment Variables](docs/N8N_ENVIRONMENT_VARIABLES.md)

### Quick Reference Commands

**Flux**:
```bash
flux check
flux get kustomizations
flux reconcile source git antigravity-odoo
```

**Kubernetes**:
```bash
kubectl get pods -n antigravity-dev
kubectl logs -f <pod-name> -n antigravity-dev
kubectl get events -n antigravity-dev --sort-by='.lastTimestamp'
```
