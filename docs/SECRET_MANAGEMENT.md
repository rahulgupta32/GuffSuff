# GuffSuff Secret Management Policy & Environment Rules

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Rule**: Hardcoded secrets, production credentials in Git, and unencrypted secret files are strictly forbidden across all environments.

---

## 1. Environment Secrets Rules

### Local Development Environment

- ONLY mock / dummy credentials permitted in local `.env` files.
- Local `.env` and `.env.local` files MUST be explicitly listed in root `.gitignore`.
- Developers inject secrets via local environment variables or mock secret services.

### CI / CD Environment (GitHub Actions)

- Use short-lived OIDC tokens for cloud provider authentication where supported.
- Pass production credentials exclusively via GitHub Actions Protected Environment Secrets.
- Restrict CI secret visibility to approved deployment workflows on protected branches.

### Staging & Production Environments

- Production secrets MUST be managed via a dedicated Secrets Manager (e.g. AWS Secrets Manager / HashiCorp Vault).
- Services access secrets via IAM Workload Identity without writing plaintext secret files to disk.
- Production credentials MUST be isolated from staging credentials.

---

## 2. Leak Detection & Incident Response

Automated pre-commit hooks (`gitleaks`), CI pipeline secret scanners, and repository push protection actively monitor for leaks across:

- Git commit history and PR diffs.
- Build logs and container layer outputs.
- Mobile application binaries (APK/AAB/IPA).
- Administrative web client bundles.

> **LEAK RESPONSE PROCEDURE**: If a secret is detected in Git or build logs, follow runbook [`docs/runbooks/credential-leak.md`](runbooks/credential-leak.md) immediately to revoke, rotate, and scrub the repository.
