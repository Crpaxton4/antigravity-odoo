#!/bin/sh
# pgAdmin entrypoint wrapper
# This script generates the pgpass file with actual environment variable values
# before starting pgAdmin

set -e

echo "========================================"
echo "pgAdmin Startup - Generating pgpass"
echo "========================================"

# Check if POSTGRES_ADMIN_PASSWORD is set
if [ -z "${POSTGRES_ADMIN_PASSWORD}" ]; then
    echo "❌ ERROR: POSTGRES_ADMIN_PASSWORD environment variable is not set"
    echo "   Please set it in your .env file or docker-compose environment"
    exit 1
fi

# Use secure location for pgpass file (pgadmin home directory)
# This prevents exposure to other system users in /tmp
PGPASS_DIR="/var/lib/pgadmin"
PGPASS_FILE="${PGPASS_DIR}/.pgpass"

# Ensure directory exists and has correct permissions
if [ ! -d "${PGPASS_DIR}" ]; then
    echo "📁 Creating secure directory: ${PGPASS_DIR}"
    mkdir -p "${PGPASS_DIR}"
    chmod 0700 "${PGPASS_DIR}"
fi

echo "📝 Creating pgpass file at ${PGPASS_FILE}..."

# Write the pgpass file with the actual password from environment
cat > "${PGPASS_FILE}" <<EOF
postgres:5432:*:pgadmin:${POSTGRES_ADMIN_PASSWORD}
EOF

# Set proper permissions (required by PostgreSQL/pgAdmin)
# 0600 = owner read/write only, prevents access by other users
chmod 0600 "${PGPASS_FILE}"

# Ensure ownership is correct (pgadmin user)
# This prevents other users from reading the file even if permissions are changed
chown "$(id -u):$(id -g)" "${PGPASS_FILE}" 2>/dev/null || true

echo "✅ pgpass file created successfully"
echo "   File: ${PGPASS_FILE}"
echo "   Permissions: $(stat -c '%a' "${PGPASS_FILE}" 2>/dev/null || stat -f '%OLp' "${PGPASS_FILE}" 2>/dev/null)"
echo "========================================"
echo ""

# Execute the original pgAdmin entrypoint
exec /entrypoint.sh "$@"
