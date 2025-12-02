# Grafana Dashboards

This directory contains Grafana dashboard configurations.

## Pre-built Dashboards

You can import the following community dashboards from Grafana.com:

### Container Monitoring (cAdvisor)
- **Dashboard ID**: 14282
- **Name**: cAdvisor exporter
- **URL**: https://grafana.com/grafana/dashboards/14282

### PostgreSQL Monitoring
- **Dashboard ID**: 9628
- **Name**: PostgreSQL Database
- **URL**: https://grafana.com/grafana/dashboards/9628

### Node/System Monitoring
- **Dashboard ID**: 1860
- **Name**: Node Exporter Full
- **URL**: https://grafana.com/grafana/dashboards/1860

## How to Import

1. Access Grafana at http://localhost:3000
2. Login with credentials from .env file (default: admin/admin)
3. Go to Dashboards → Import
4. Enter the Dashboard ID
5. Select "Prometheus" as the data source
6. Click "Import"

## Custom Dashboards

You can create custom dashboards and export them as JSON files to this directory for version control.
