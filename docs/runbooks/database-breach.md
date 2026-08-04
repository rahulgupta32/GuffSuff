# Security Incident Runbook: Database Breach Response

> **Target Role**: `@database-architect`, `@security-lead`  
> **Trigger**: Unauthorized access or data exfiltration alert from PostgreSQL cluster.

---

## Response Steps

1. **Isolate Database Node**: Block unauthorized IP address or close external DB connection pools at WAF / firewall.
2. **Credential Rotation**: Instantly rotate database superuser and application service passwords.
3. **Assess Zero-Knowledge Impact**: Confirm that exfiltrated tables contain zero message plaintext or private keys.
4. **Forensic Log Audit**: Query PostgreSQL WAL audit logs to identify queried tables and byte volumes.
5. **Regulatory Disclosure**: Prepare incident disclosure report for product owner `@rahulgupta32`.
