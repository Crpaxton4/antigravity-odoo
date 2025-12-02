# pgAdmin Configuration

This directory contains configuration files for pgAdmin.

## Files

### `pgpass.example` (Template)

This is a **template file** showing the PostgreSQL password file format. It should **never** contain real credentials.

**⚠️ SECURITY WARNING:**
- The actual `pgpass` file is **gitignored** and must not be committed to version control
- The `pgpass` file contains database credentials in plaintext
- This file is handled differently for Docker vs local usage

### `docker-entrypoint.sh`

Custom entrypoint script for the pgAdmin Docker container that:
- Generates `.pgpass` file at container startup in secure location
- Reads `POSTGRES_ADMIN_PASSWORD` from environment variables
- Creates file at `/var/lib/pgadmin/.pgpass` (pgadmin home directory)
- **Security**: Not stored in `/tmp` which is accessible to all system users
- Sets correct file permissions (0600) and ownership
- Then starts pgAdmin normally

### `setup-pgpass.sh`

Local development script for non-Docker usage that:
- Reads password from `.env` file
- Creates `pgpass` file with actual password
- Sets correct permissions (0600)

### `servers.json`

Configuration file that defines the PostgreSQL server connections in pgAdmin.

## Setup Instructions

### Docker Compose (Automatic)

When using Docker Compose, pgpass is **automatically generated** at container startup:

1. **Set environment variable in `.env`:**
   ```bash
   POSTGRES_ADMIN_PASSWORD=your_secure_password
   ```

2. **Start containers:**
   ```bash
   docker compose up -d pgadmin
   ```

3. **How it works:**
   - `docker-entrypoint.sh` runs when container starts
   - Reads `POSTGRES_ADMIN_PASSWORD` from environment
   - Generates `/var/lib/pgadmin/.pgpass` with actual password (secure location)
   - Sets permissions to 0600 and ownership to pgadmin user
   - Starts pgAdmin

**No manual pgpass creation needed for Docker!**

### Local Development (Manual)

For running pgAdmin outside Docker, use the setup script:

For running pgAdmin outside Docker, use the setup script:

1. **Ensure `.env` file exists:**
   ```bash
   cp .env.example .env
   # Edit .env and set POSTGRES_ADMIN_PASSWORD
   ```

2. **Run the setup script:**
   ```bash
   ./pgadmin/setup-pgpass.sh
   ```

   This script will:
   - Read `POSTGRES_ADMIN_PASSWORD` from `.env`
   - Create `pgpass` file with the actual password
   - Set permissions to 0600
   - Validate the setup

3. **Verify permissions:**
   ```bash
   ls -la pgadmin/pgpass
   # Should show: -rw------- (0600)
   ```

### File Format

The `pgpass` file follows the standard PostgreSQL password file format:

```
hostname:port:database:username:password
```

**Template (`pgpass.example`):**
```
postgres:5432:*:pgadmin:CHANGEME
```

**Generated file (Docker/Local):**
```
postgres:5432:*:pgadmin:actual_password_from_env
```

Where:
- `hostname`: `postgres` (the Docker service name)
- `port`: `5432` (PostgreSQL default port)
- `database`: `*` (matches all databases)
- `username`: `pgadmin` (the PostgreSQL user)
- `password`: `${POSTGRES_ADMIN_PASSWORD}` (environment variable)

### Docker Compose Integration

**Docker Approach (Automatic):**

The pgpass file is generated automatically at container startup:

```yaml
pgadmin:
  entrypoint: ["/docker-entrypoint.sh"]
  environment:
    - POSTGRES_ADMIN_PASSWORD=${POSTGRES_ADMIN_PASSWORD}
  volumes:
    - ./pgadmin/docker-entrypoint.sh:/docker-entrypoint.sh:ro
```

The entrypoint script:
1. Checks `POSTGRES_ADMIN_PASSWORD` is set
2. Generates `/var/lib/pgadmin/.pgpass` with actual password
3. Sets permissions to 0600 and ownership to pgadmin user
4. Starts pgAdmin

**Why `/var/lib/pgadmin/.pgpass`?**
- Located in pgadmin user's home directory (secure, isolated)
- Not in `/tmp` which is world-readable by all system users
- Prevents privilege escalation and unauthorized access
- Follows PostgreSQL security best practices

**Local Approach (Manual):**

For development outside Docker, the `pgpass` file must be created manually using `setup-pgpass.sh`.

## Security Best Practices

### ✅ DO:

- ✅ Use `pgpass.example` as a template
- ✅ Create `pgpass` with proper permissions (0600)
- ✅ Use strong passwords
- ✅ Verify `pgpass` is in `.gitignore`
- ✅ Rotate passwords regularly
- ✅ Use environment variables for sensitive values

### ❌ DON'T:

- ❌ Commit `pgpass` to version control
- ❌ Use default or weak passwords
- ❌ Share the `pgpass` file
- ❌ Set permissions higher than 0600
- ❌ Hardcode passwords directly in the file

## Automated Setup Script

### For Local Development (Non-Docker)

Use the provided setup script to automatically create the file with correct permissions:

```bash
./pgadmin/setup-pgpass.sh
```

This script will:
1. Check if `.env` file exists
2. Read `POSTGRES_ADMIN_PASSWORD` from `.env`
3. Create `pgpass` with actual password
4. Set permissions to 0600
5. Verify the setup

### For Docker Compose

**No manual setup required!** The `docker-entrypoint.sh` script automatically:
1. Reads `POSTGRES_ADMIN_PASSWORD` from environment
2. Generates `/var/lib/pgadmin/.pgpass` at container startup (secure location)
3. Sets correct permissions (0600) and ownership (pgadmin user)
4. Starts pgAdmin

## Troubleshooting

### Connection fails with "permission denied"

**Issue:** pgAdmin can't read the pgpass file.

**Solution:**
```bash
chmod 0600 pgadmin/pgpass
```

### Connection fails with authentication error

**Issue:** Password is incorrect or environment variable not set.

**Solution:**
1. Check your `.env` file has `POSTGRES_ADMIN_PASSWORD` set
2. Restart the containers: `docker compose restart pgadmin`
3. Verify the password matches the PostgreSQL configuration

### File not found error

**Issue:** `pgpass` file doesn't exist.

**Solution:**
```bash
cp pgadmin/pgpass.example pgadmin/pgpass
chmod 0600 pgadmin/pgpass
```

## Code Review Checklist

When reviewing PRs that modify pgAdmin configuration:

- [ ] `pgpass` file is NOT included in the commit
- [ ] Only `pgpass.example` is modified (if at all)
- [ ] `.gitignore` includes `pgadmin/pgpass`
- [ ] No real credentials are hardcoded anywhere
- [ ] Documentation is updated if file format changes
- [ ] Setup script is updated if process changes

## Related Files

- `.gitignore` - Excludes `pgpass` from version control
- `.env.example` - Template for environment variables
- `docker-compose.yml` - Mounts pgpass into container
- `servers.json` - pgAdmin server definitions

## References

- [PostgreSQL Password File Documentation](https://www.postgresql.org/docs/current/libpq-pgpass.html)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [Docker Compose Secrets](https://docs.docker.com/compose/use-secrets/)

## Support

For questions or issues:
1. Check the troubleshooting section above
2. Review the security best practices
3. Contact the DevOps team
4. Open an issue in the project repository
