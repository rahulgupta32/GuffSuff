# Security Incident Runbook: Dependency Zero-Day Vulnerability Response

> **Target Role**: `@devsecops-team`, `@security-lead`  
> **Trigger**: Disclosure of zero-day vulnerability (RCE / auth bypass) in production npm / pub package.

---

## Response Steps

1. **Verify Exposure**: Check monorepo dependency graph and lockfiles for vulnerable package.
2. **Apply Patch / Override**: Apply vendor security patch or add `overrides` in `package.json`.
3. **Emergency CI Build**: Run CI build and test suite.
4. **Deploy Hotfix**: Deploy updated container images to production nodes (`SEC-DEPENDENCY-001`).
