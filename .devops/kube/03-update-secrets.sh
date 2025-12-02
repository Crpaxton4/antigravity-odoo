#!/bin/bash
# Script to update secrets in Flux HelmRelease manifests

set -e

echo "=========================================="
echo "Updating Secrets Configuration"
echo "=========================================="
echo ""

RELEASES_DIR="kubernetes/flux/releases/dev"

# Function to generate random password
generate_password() {
    openssl rand -base64 24 | tr -d "=+/" | cut -c1-24
}

# Ask user if they want to auto-generate passwords
echo "This script will update passwords in HelmRelease manifests."
echo ""
read -p "Auto-generate secure passwords? (Y/n): " -n 1 -r
echo
AUTO_GEN=true
if [[ $REPLY =~ ^[Nn]$ ]]; then
    AUTO_GEN=false
fi

echo ""

# Update PostgreSQL passwords
echo "Updating PostgreSQL passwords..."

if [ "$AUTO_GEN" = true ]; then
    POSTGRES_PASSWORD=$(generate_password)
    ADMIN_PASSWORD=$(generate_password)
    ODOO_PASSWORD=$(generate_password)
    N8N_PASSWORD=$(generate_password)
    GRAFANA_PASSWORD=$(generate_password)
    
    echo "✓ Generated secure passwords"
else
    read -sp "PostgreSQL superuser password: " POSTGRES_PASSWORD
    echo
    read -sp "Admin password: " ADMIN_PASSWORD
    echo
    read -sp "Odoo database password: " ODOO_PASSWORD
    echo
    read -sp "n8n database password: " N8N_PASSWORD
    echo
    read -sp "Grafana database password: " GRAFANA_PASSWORD
    echo
fi

# Update postgresql.yaml
sed -i.bak "s/postgresPassword: \".*\"/postgresPassword: \"$POSTGRES_PASSWORD\"/" "$RELEASES_DIR/postgresql.yaml"
sed -i.bak "s/adminPassword: \".*\"/adminPassword: \"$ADMIN_PASSWORD\"/" "$RELEASES_DIR/postgresql.yaml"
sed -i.bak "s/odoo:$/odoo:\n        password: \"$ODOO_PASSWORD\"/" "$RELEASES_DIR/postgresql.yaml" || sed -i.bak "s/password: \".*\" # odoo/password: \"$ODOO_PASSWORD\"/" "$RELEASES_DIR/postgresql.yaml"
sed -i.bak "s/n8n:$/n8n:\n        password: \"$N8N_PASSWORD\"/" "$RELEASES_DIR/postgresql.yaml" || sed -i.bak "s/password: \".*\" # n8n/password: \"$N8N_PASSWORD\"/" "$RELEASES_DIR/postgresql.yaml"
sed -i.bak "s/grafana:$/grafana:\n        password: \"$GRAFANA_PASSWORD\"/" "$RELEASES_DIR/postgresql.yaml" || sed -i.bak "s/password: \".*\" # grafana/password: \"$GRAFANA_PASSWORD\"/" "$RELEASES_DIR/postgresql.yaml"

echo "✓ Updated $RELEASES_DIR/postgresql.yaml"

# Update odoo.yaml
sed -i.bak "s/password: \".*\"/password: \"$ODOO_PASSWORD\"/" "$RELEASES_DIR/odoo.yaml"
echo "✓ Updated $RELEASES_DIR/odoo.yaml"

# Update n8n.yaml
sed -i.bak "s/password: \".*\"/password: \"$N8N_PASSWORD\"/" "$RELEASES_DIR/n8n.yaml"
echo "✓ Updated $RELEASES_DIR/n8n.yaml"

# Update others.yaml (pgadmin and grafana)
sed -i.bak "s/password: \".*\"/password: \"$GRAFANA_PASSWORD\"/" "$RELEASES_DIR/others.yaml"
echo "✓ Updated $RELEASES_DIR/others.yaml"

# Clean up backup files
rm -f "$RELEASES_DIR"/*.bak

echo ""
echo "✓ All secrets updated successfully!"
echo ""

# Save passwords to secure location if auto-generated
if [ "$AUTO_GEN" = true ]; then
    SECRETS_FILE=".devops/kube/.secrets.txt"
    cat > "$SECRETS_FILE" <<EOF
# Generated Passwords - $(date)
# KEEP THIS FILE SECURE - DO NOT COMMIT TO GIT

POSTGRES_SUPERUSER_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_ADMIN_PASSWORD=$ADMIN_PASSWORD
ODOO_DB_PASSWORD=$ODOO_PASSWORD
N8N_DB_PASSWORD=$N8N_PASSWORD
GRAFANA_DB_PASSWORD=$GRAFANA_PASSWORD
EOF
    
    chmod 600 "$SECRETS_FILE"
    
    echo "⚠️  Passwords saved to: $SECRETS_FILE"
    echo "    Keep this file secure and DO NOT commit to Git!"
    echo "    (Already added to .gitignore)"
    echo ""
fi

echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Update Git repository URL:"
echo "   ./.devops/kube/04-update-git-repo.sh"
echo ""
echo "2. Or skip to deployment:"
echo "   ./.devops/kube/06-deploy.sh"
echo ""
