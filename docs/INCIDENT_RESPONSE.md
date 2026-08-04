# GuffSuff Security Incident Response Framework

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Rule**: Public repository runbooks MUST use role aliases (e.g. `@security-lead`) and generic secure placeholders instead of personal contact numbers.

---

## 1. Incident Severity Classification

| Incident Level | Criteria / Trigger Example | Response SLA | Incident Commander Role | Escalation Target |
| :--- | :--- | :--- | :--- | :--- |
| **SEV-1 (Critical)** | Active data breach, secret leak, compromise of signing keys or database. | Immediate (< 15 mins) | Lead Security Engineer | CISO & Product Owner |
| **SEV-2 (High)** | Disruption of OTP authentication or realtime WebSocket gateway; severe rate-limit bypass. | < 1 Hour | Operations Lead | DevSecOps Lead |
| **SEV-3 (Medium)**| Non-critical API degradation or localized abuse surge. | < 4 Hours | Backend Lead | Operations Lead |
| **SEV-4 (Low)** | Minor security finding or non-exploitable dependency vulnerability. | < 24 Hours | Security Engineer | Module Lead |

---

## 2. Master Runbook Directory (`docs/runbooks/`)

1. [`credential-leak.md`](runbooks/credential-leak.md): Response to committed API keys or DB passwords.
2. [`signing-key-compromise.md`](runbooks/signing-key-compromise.md): Response to compromised APK/IPA signing keys.
3. [`device-key-compromise.md`](runbooks/device-key-compromise.md): Response to stolen user identity keys.
4. [`database-breach.md`](runbooks/database-breach.md): Response to unauthorized PostgreSQL access.
5. [`object-storage-exposure.md`](runbooks/object-storage-exposure.md): Response to public S3 bucket exposure.
6. [`admin-account-compromise.md`](runbooks/admin-account-compromise.md): Response to compromised admin MFA/session.
7. [`otp-provider-compromise.md`](runbooks/otp-provider-compromise.md): Response to SMS vendor breach or toll fraud.
8. [`dependency-zero-day.md`](runbooks/dependency-zero-day.md): Response to critical zero-day in open-source package.
9. [`malicious-release.md`](runbooks/malicious-release.md): Response to unauthorized or tampered mobile release binary.
10. [`account-takeover.md`](runbooks/account-takeover.md): Response to SIM-swap or OTP interception takeover.
11. [`abuse-surge.md`](runbooks/abuse-surge.md): Response to coordinated spam or botnet attacks.
12. [`security-incident-triage.md`](runbooks/security-incident-triage.md): Master incident triage and escalation workflow.
