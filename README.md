# Consolidated PostgreSQL + Monitoring Stack

This repository now uses a single PostgreSQL instance for both Odoo and n8n, with comprehensive monitoring via Grafana.

## Architecture

### Database Structure
- **Single PostgreSQL Instance**: Serves both Odoo and n8n
- **Isolated Users**: 
  - `odoo_user`: Access only to `odoo_db` (CREATE, READ, UPDATE - no DROP DATABASE)
  - `n8n_user`: Access only to `n8n_db` (CREATE, READ, UPDATE - no DROP DATABASE)
  - `pgadmin`: Superuser for manual administration

### Monitoring Stack
- **Grafana**: Visualization and dashboards (http://localhost:3000)
- **Prometheus**: Metrics collection (http://localhost:9090)
- **cAdvisor**: Container metrics (http://localhost:8080)
- **PostgreSQL Exporter**: Database metrics
- **pgAdmin**: Database administration (http://localhost:5050)

## Services and Ports

| Service | Port | Purpose |
|---------|------|---------|
| Odoo | 8069 | ERP system |
| Odoo Debug | 5678 | VS Code debugger |
| n8n | 5679 | Workflow automation |
| Ollama | 11435 | Local LLM |
| pgAdmin | 5050 | Database admin |
| Grafana | 3000 | Monitoring dashboards |
| Prometheus | 9090 | Metrics |
| cAdvisor | 8080 | Container metrics |

## Environment Variables

Copy `temp.env` to `.env` and update the following:

### Required
- `POSTGRES_PASSWORD`: Main PostgreSQL superuser password
- `POSTGRES_ADMIN_PASSWORD`: Admin user password for pgAdmin
- `POSTGRES_ODOO_PASSWORD`: Odoo database user password
- `POSTGRES_N8N_PASSWORD`: n8n database user password
- `PGADMIN_DEFAULT_EMAIL`: pgAdmin login email
- `PGADMIN_DEFAULT_PASSWORD`: pgAdmin login password
- `GF_SECURITY_ADMIN_PASSWORD`: Grafana admin password
- `N8N_ENCRYPTION_KEY`: n8n encryption key (generate with `openssl rand -base64 32`)
- `N8N_USER_MANAGEMENT_JWT_SECRET`: n8n JWT secret

## Quick Start

1. **Configure environment**:
   ```bash
   cp temp.env .env
   # Edit .env with your secure passwords
   ```

2. **Start services**:
   ```bash
   docker compose up -d
   ```

3. **Access services**:
   - Odoo: http://localhost:8069
   - n8n: http://localhost:5679
   - pgAdmin: http://localhost:5050
   - Grafana: http://localhost:3000

## Grafana Dashboards

Import these community dashboards:
- **Container Monitoring**: Dashboard ID 14282 (cAdvisor)
- **PostgreSQL**: Dashboard ID 9628
- **Node Exporter**: Dashboard ID 1860

See `grafana/provisioning/dashboards/README.md` for details.

## Database Access

### Via pgAdmin
1. Access http://localhost:5050
2. Login with credentials from `.env`
3. Server "PostgreSQL Server" is pre-configured

### Via psql
```bash
# As admin
docker exec -it postgres psql -U pgadmin -d postgres

# As Odoo user
docker exec -it postgres psql -U odoo_user -d odoo_db

# As n8n user
docker exec -it postgres psql -U n8n_user -d n8n_db
```

## Security Notes

- Odoo and n8n users **cannot drop databases** (only CREATE, READ, UPDATE)
- Each user can only access their own database
- Admin user (`pgadmin`) has full superuser access for manual administration
- All passwords should be changed from defaults in production
