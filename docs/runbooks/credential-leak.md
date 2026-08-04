# Security Incident Runbook: Credential & Secret Leak Response

> **Target Role**: `@security-lead`, `@devsecops-team`  
> **Trigger**: Detection of committed credentials, API keys, or private keys in Git history or build artifacts.

---

## Response Steps

1. **Immediate Revocation**: Instantly revoke the leaked API key, database password, or access token at the service provider.
2. **Rotate Credential**: Generate a new credential in Secrets Manager and inject into active service environments.
3. **Repository Scrubbing**: Use `git-filter-repo` or BFG Repo-Cleaner to scrub the leaked secret string from Git history.
4. **Force Push & Notify**: Push scrubbed repository state and notify repository owner `@rahulgupta32`.
5. **Post-Mortem Analysis**: Inspect access logs for the leaked credential during the exposure window to assess unauthorized activity.
