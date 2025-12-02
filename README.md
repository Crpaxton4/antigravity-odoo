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

### Automated Deployment (Minikube)

We provide automated scripts in `.devops/kube/` to streamline the process.

```bash
cd .devops/kube

# 1. Setup Cluster
./02-setup-cluster.sh

# 2. Start Tunnel (Separate Terminal)
minikube tunnel

# 3. Deploy Stack
./01-deploy-all.sh
```

### Manual Deployment

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
