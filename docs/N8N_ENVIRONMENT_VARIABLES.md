# n8n Environment Variables Documentation

This document outlines the required and recommended environment variables for the n8n setup in this repository.

## Required Variables

### Database Configuration (PostgreSQL)
```bash
POSTGRES_USER=n8n
POSTGRES_PASSWORD=n8n_password
POSTGRES_DB=n8n
```

These variables configure the PostgreSQL database that n8n uses for persistence.

### Security & Encryption

#### N8N_ENCRYPTION_KEY
**Required**: Yes  
**Purpose**: Encrypts sensitive data (credentials, API tokens, passwords) before storing in the database.

**Important Notes**:
- If not set, n8n will auto-generate one on first launch and save it in `~/.n8n`
- **CRITICAL**: Losing this key means losing access to ALL stored credentials
- Must be the same across all n8n instances in a distributed setup
- Should be a strong, random string (minimum 32 characters recommended)

**Generate a secure key**:
```bash
# Linux/Mac
openssl rand -base64 32

# Windows PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

#### N8N_USER_MANAGEMENT_JWT_SECRET
**Required**: Yes (for user management)  
**Purpose**: JWT secret for user authentication and session management.

**Important Notes**:
- If not set, n8n will auto-generate one on first launch
- Required for user login, password management, and multi-user features
- Should be a strong, random string

**Generate a secure secret**:
```bash
# Linux/Mac
openssl rand -base64 32

# Windows PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

### AI Integration

#### OLLAMA_HOST
**Required**: Yes (for AI workflows)  
**Purpose**: Specifies the Ollama service endpoint for local LLM integration.

```bash
OLLAMA_HOST=ollama:11434
```

## Optional but Recommended Variables

### Task Runners (Performance)
```bash
N8N_RUNNERS_ENABLED=true
```
Enables task runners for better performance. Will be default in future versions.

### Security Enhancements
```bash
N8N_BLOCK_ENV_ACCESS_IN_NODE=false
```
Controls whether Code Node can access environment variables. Set to `true` for enhanced security.

```bash
N8N_GIT_NODE_DISABLE_BARE_REPOS=true
```
Disables bare repositories in Git Node for security.

### Diagnostics & Telemetry
```bash
N8N_DIAGNOSTICS_ENABLED=false
N8N_PERSONALIZATION_ENABLED=false
```
Disable telemetry and personalization for privacy.

## Current Configuration

Our `.env.example` file contains the minimal required variables:
- PostgreSQL connection details
- Encryption key (placeholder - must be changed)
- JWT secret (placeholder - must be changed)
- Ollama host configuration

## Setup Instructions

1. **Copy the example file**:
   ```bash
   cp .env.example .env
   ```

2. **Generate secure keys**:
   ```bash
   # Generate encryption key
   openssl rand -base64 32
   
   # Generate JWT secret
   openssl rand -base64 32
   ```

3. **Update `.env` file** with the generated keys

4. **Never commit `.env`** to version control (already in `.gitignore`)

## References

- [n8n Environment Variables Documentation](https://docs.n8n.io/hosting/configuration/environment-variables/)
- [Database Configuration](https://docs.n8n.io/hosting/configuration/environment-variables/database/)
- [Security Variables](https://docs.n8n.io/hosting/configuration/environment-variables/security/)
- [User Management](https://docs.n8n.io/hosting/configuration/environment-variables/user-management-smtp-2fa/)
