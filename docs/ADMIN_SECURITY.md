# GuffSuff Administrative Console Security & Privilege Controls

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Rule**: Zero-Knowledge Privacy Architecture strictly prohibits administrator access to un-reported message plaintext or private keys (`SEC-ADMIN-001`).

---

## 1. Authentication & Session Controls

- **Mandatory Multi-Factor Authentication (MFA)**: WebAuthn / FIDO2 security keys or TOTP MFA required for all administrative accounts.
- **Short Session Lifetimes**: Admin Web sessions expire after **15 minutes** of inactivity with mandatory re-authentication.
- **IP Allowlisting & Posture**: Restrict admin console access to corporate VPN IP ranges and managed devices.

---

## 2. Four-Eyes Approval Policy

The following high-impact administrative actions MUST require explicit approval from **two independent administrators** (Four-Eyes Principle):

1. Permanent global user account bans (`PERMANENT_BAN`).
2. Bulk user account suspensions (> 10 accounts in a single operation).
3. Exporting administrative audit logs or user report metadata zips.
4. Overriding system-wide rate-limiting or abuse detection thresholds.
5. Invoking break-glass administrative recovery procedures.
6. Overriding account deletion requests.

All administrative actions write immutable audit records to `admin_audit_events` (`SEC-IR-001`).
