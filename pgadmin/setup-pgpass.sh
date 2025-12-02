#!/bin/bash
# Setup script for pgAdmin pgpass file
# This script creates the pgpass file from the template with correct permissions
# and substitutes the actual password from .env file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PGPASS_FILE="${SCRIPT_DIR}/pgpass"
PGPASS_EXAMPLE="${SCRIPT_DIR}/pgpass.example"
ENV_FILE="${PROJECT_ROOT}/.env"

echo "=========================================="
echo "pgAdmin pgpass Setup"
echo "=========================================="
echo ""

# Check if example file exists
if [ ! -f "$PGPASS_EXAMPLE" ]; then
    echo "❌ Error: pgpass.example not found at $PGPASS_EXAMPLE"
    exit 1
fi

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found at $ENV_FILE"
    echo "   Please create it from .env.example first:"
    echo "   cp .env.example .env"
    exit 1
fi

# Load POSTGRES_ADMIN_PASSWORD from .env
echo "📄 Loading password from .env file..."
if grep -q "^POSTGRES_ADMIN_PASSWORD=" "$ENV_FILE"; then
    POSTGRES_ADMIN_PASSWORD=$(grep "^POSTGRES_ADMIN_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2-)
    # Remove quotes if present
    POSTGRES_ADMIN_PASSWORD=$(echo "$POSTGRES_ADMIN_PASSWORD" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
else
    echo "❌ Error: POSTGRES_ADMIN_PASSWORD not found in .env file"
    echo "   Please add it to your .env file:"
    echo "   POSTGRES_ADMIN_PASSWORD=your_secure_password"
    exit 1
fi

if [ -z "$POSTGRES_ADMIN_PASSWORD" ] || [ "$POSTGRES_ADMIN_PASSWORD" = "CHANGEME" ]; then
    echo "⚠️  Warning: POSTGRES_ADMIN_PASSWORD is not set or uses default value"
    echo "   Please set a secure password in your .env file"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Check if pgpass already exists
if [ -f "$PGPASS_FILE" ]; then
    echo "⚠️  Warning: pgpass file already exists at $PGPASS_FILE"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled. Existing file preserved."
        echo ""
        echo "To verify permissions, run:"
        echo "  ls -la $PGPASS_FILE"
        exit 0
    fi
fi

# Create the pgpass file with actual password
echo "📄 Creating pgpass file with password from .env..."
cat > "$PGPASS_FILE" <<EOF
postgres:5432:*:pgadmin:${POSTGRES_ADMIN_PASSWORD}
EOF

# Set proper permissions (0600 = owner read/write only)
echo "🔒 Setting permissions to 0600..."
chmod 0600 "$PGPASS_FILE"

# Verify permissions
ACTUAL_PERMS=$(stat -c "%a" "$PGPASS_FILE" 2>/dev/null || stat -f "%OLp" "$PGPASS_FILE" 2>/dev/null)

if [ "$ACTUAL_PERMS" = "600" ]; then
    echo "✅ Success! pgpass file created with correct permissions."
else
    echo "⚠️  Warning: Permissions are $ACTUAL_PERMS instead of 600"
    echo "   This may cause authentication issues."
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "✅ pgpass file created: $PGPASS_FILE"
echo "✅ Password loaded from: $ENV_FILE"
echo "✅ Permissions set to: 0600"
echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Start the containers:"
echo "   docker compose up -d"
echo ""
echo "2. Access pgAdmin at:"
echo "   http://localhost:5050"
echo ""
echo "⚠️  SECURITY REMINDER:"
echo "   - Never commit pgpass to git (it's in .gitignore)"
echo "   - Keep permissions at 0600"
echo "   - Use strong passwords in .env"
echo ""

