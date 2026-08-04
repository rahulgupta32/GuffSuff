# Security Incident Runbook: Admin Account Compromise Response

> **Target Role**: `@security-lead`, `@admin-team`  
> **Trigger**: Suspicious login or un-authorized administrative action detected.

---

## Response Steps

1. **Revoke Admin Session**: Instantly terminate active admin session JWTs and clear session tokens in Redis.
2. **Disable Admin Account**: Set admin user status to `SUSPENDED` in `admin_users` table.
3. **MFA Reset**: Force WebAuthn / TOTP secret reset for compromised account.
4. **Audit Log Inspection**: Review `admin_audit_events` to identify and revert unauthorized administrative actions.
