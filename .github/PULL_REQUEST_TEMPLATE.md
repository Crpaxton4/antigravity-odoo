# Pull Request Checklist

Thank you for your contribution! Please ensure your PR meets the following requirements:

## General

- [ ] PR title clearly describes the change
- [ ] Description explains the what, why, and how
- [ ] Related issues are linked (e.g., "Fixes #123")
- [ ] Changes are rebased on the latest main branch
- [ ] All CI/CD checks pass

## Code Quality

- [ ] Code follows project style guidelines
- [ ] No commented-out code or debug statements
- [ ] Error handling is appropriate
- [ ] Code is self-documenting or includes necessary comments

## Testing

- [ ] New code includes appropriate tests
- [ ] All existing tests pass
- [ ] Manual testing performed (describe in PR description)

## Documentation

- [ ] README updated if needed
- [ ] Inline documentation added for complex logic
- [ ] Configuration examples updated if applicable
- [ ] CHANGELOG updated (if maintained)

## Security (⚠️ CRITICAL)

### Credentials and Secrets

- [ ] **No hardcoded passwords, API keys, or secrets in code**
- [ ] **No real credentials in configuration files**
- [ ] **Secrets use environment variables or secret management**
- [ ] **Example/template files clearly marked (e.g., `.example` suffix)**

### pgAdmin Configuration

If your PR modifies anything in the `pgadmin/` directory:

- [ ] **`pgpass` file is NOT included in the commit** (only `pgpass.example`)
- [ ] **`pgpass` is listed in `.gitignore`**
- [ ] **No real database credentials in `pgpass.example`**
- [ ] **Documentation updated if file format changes**
- [ ] **Setup script (`setup-pgpass.sh`) creates file with 0600 permissions**

### Database Credentials

- [ ] **Database passwords stored in Kubernetes Secrets (not ConfigMaps)**
- [ ] **No plaintext passwords in Helm values files**
- [ ] **Credentials reference secretKeyRef or external secrets**
- [ ] **Secret creation documented for each environment**

### Docker Compose

- [ ] **No hardcoded passwords in `docker-compose.yml`**
- [ ] **All secrets use environment variables from `.env`**
- [ ] **`.env` file is gitignored**
- [ ] **`.env.example` uses placeholder values (e.g., `CHANGEME`)**

### Kubernetes Manifests

- [ ] **No hardcoded passwords in YAML files**
- [ ] **Secrets created separately (not committed to git)**
- [ ] **HelmRelease uses `passwordSecretRef` for credentials**
- [ ] **Secret names and keys documented in README**

### Scripts and Automation

- [ ] **Shell scripts validate/sanitize user input**
- [ ] **No path traversal vulnerabilities (e.g., `..` in paths)**
- [ ] **File operations use absolute paths or validated relative paths**
- [ ] **Script sets appropriate file permissions (e.g., 0600 for credentials)**

## Deployment

- [ ] Changes work in local development environment
- [ ] Migration path documented for existing deployments
- [ ] Backward compatibility considered
- [ ] Breaking changes clearly documented

## Environment-Specific

### Development (`dev`)

- [ ] Changes tested locally with Docker Compose
- [ ] Debug mode enabled/disabled appropriately

### Staging (`staging`)

- [ ] Staging secrets created (if needed)
- [ ] Debug mode disabled
- [ ] Resource limits appropriate for staging

### Production (`prod`)

- [ ] Production secrets created via secure method
- [ ] Debug mode disabled
- [ ] Resource limits appropriate for production
- [ ] High availability considered (replicas, anti-affinity)
- [ ] Monitoring and alerting configured

## Infrastructure Changes

If your PR modifies Kubernetes resources:

- [ ] Changes tested in Minikube or similar
- [ ] Resource requests and limits defined
- [ ] Health checks configured (liveness, readiness, startup)
- [ ] Persistent volumes configured if needed
- [ ] Network policies reviewed

If your PR modifies Helm charts:

- [ ] Chart version bumped
- [ ] Values documented in `values.yaml`
- [ ] Templates properly tested
- [ ] Support for external secrets added where needed

## GitOps and Flux

- [ ] Flux manifests use correct Git repository reference
- [ ] HelmRelease dependencies properly configured
- [ ] Reconciliation intervals appropriate
- [ ] Changes will be picked up by Flux automatically

## Security Review Checklist (for Reviewers)

**Before approving, verify:**

1. **No credentials in code**: Use `git diff` and search for patterns:
   - `password:`
   - `secret:`
   - `token:`
   - `api_key:`
   - Base64-encoded strings that might be secrets

2. **Proper file permissions**: Check scripts set appropriate permissions:
   ```bash
   grep -r "chmod" .
   ```

3. **Input validation**: Check user input is validated:
   ```bash
   grep -A5 "read.*-p\|BASH_ARGV\|\$1\|\$2" **/*.sh
   ```

4. **Secret references**: Verify Kubernetes resources use secretKeyRef:
   ```bash
   grep -r "password:" kubernetes/
   ```

5. **Gitignore coverage**: Verify sensitive files are ignored:
   ```bash
   git ls-files | grep -E "(pgpass|\.env|secret)"
   ```

## Additional Notes

<!-- Add any additional context, screenshots, or notes here -->

---

**By submitting this PR, I confirm that:**

- [ ] I have read and followed the security guidelines above
- [ ] I have not committed any credentials, secrets, or sensitive information
- [ ] I understand the security implications of my changes
- [ ] I have tested my changes in an appropriate environment

