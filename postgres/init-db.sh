#!/bin/bash
set -e

# This script initializes the PostgreSQL database with:
# 1. Admin user with full access
# 2. Odoo user with restricted permissions
# 3. n8n user with restricted permissions
# 4. Grafana user with restricted permissions

# NOTE: To prevent users from deleting databases, we ensure the databases are owned by the superuser (pgadmin).
# Service users are granted full privileges on the database and schema, but since they are not the owner,
# they cannot DROP the database. They are granted CREATEDB to allow creating *new* databases if needed.

echo "Creating admin user..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create admin user with full superuser privileges
    CREATE USER postgres_admin WITH PASSWORD '${POSTGRES_ADMIN_PASSWORD}' SUPERUSER CREATEDB CREATEROLE;
EOSQL

echo "Creating Odoo user and database..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create Odoo user with CREATEDB (required for Odoo to create test DBs)
    CREATE USER odoo_user WITH PASSWORD '${POSTGRES_ODOO_PASSWORD}' CREATEDB;
    
    -- Create Odoo database owned by ADMIN to prevent deletion by odoo_user
    CREATE DATABASE odoo_db OWNER postgres_admin;
    
    -- Grant privileges to Odoo user
    GRANT ALL PRIVILEGES ON DATABASE odoo_db TO odoo_user;
    
    -- Connect to odoo_db and grant schema privileges
    \c odoo_db
    GRANT ALL ON SCHEMA public TO odoo_user;
    ALTER SCHEMA public OWNER TO odoo_user; 
EOSQL

echo "Creating n8n user and database..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create n8n user
    CREATE USER n8n_user WITH PASSWORD '${POSTGRES_N8N_PASSWORD}' CREATEDB;
    
    -- Create n8n database owned by ADMIN to prevent deletion
    CREATE DATABASE n8n_db OWNER postgres_admin;
    
    -- Grant privileges to n8n user
    GRANT ALL PRIVILEGES ON DATABASE n8n_db TO n8n_user;
    
    -- Connect to n8n_db
    \c n8n_db
    
    -- Enable pgvector extension for AI capabilities (must be done by superuser)
    CREATE EXTENSION IF NOT EXISTS vector;
    
    -- Grant schema privileges
    GRANT ALL ON SCHEMA public TO n8n_user;
    ALTER SCHEMA public OWNER TO n8n_user;
EOSQL

echo "Creating Grafana user and database..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create Grafana user
    CREATE USER grafana_user WITH PASSWORD '${POSTGRES_GRAFANA_PASSWORD}' CREATEDB;
    
    -- Create Grafana database owned by ADMIN to prevent deletion
    CREATE DATABASE grafana_db OWNER postgres_admin;
    
    -- Grant privileges to Grafana user
    GRANT ALL PRIVILEGES ON DATABASE grafana_db TO grafana_user;
    
    -- Connect to grafana_db
    \c grafana_db
    
    -- Grant schema privileges
    GRANT ALL ON SCHEMA public TO grafana_user;
    ALTER SCHEMA public OWNER TO grafana_user;
EOSQL

echo "Database initialization complete!"
echo "Created databases: odoo_db, n8n_db (with vector), grafana_db"
echo "Created users: postgres_admin (superuser), odoo_user, n8n_user, grafana_user"
echo "Security: Main databases are owned by postgres_admin to prevent deletion by service users."
