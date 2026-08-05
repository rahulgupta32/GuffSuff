# GuffSuff Privacy Data Inventory & Classification Matrix

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Compliance Alignment**: Data Minimization & Privacy Rights Frameworks

---

## Data Element Inventory

| Data Element                   | Source         | Operational Purpose       | Classification      | DB / Service Location    | Encryption State      | Retention Period                       | Deletion Method          | Access Roles            | Log Restrictions           | Export Behavior    | Third-Party Disclosure      | User Control      |
| :----------------------------- | :------------- | :------------------------ | :------------------ | :----------------------- | :-------------------- | :------------------------------------- | :----------------------- | :---------------------- | :------------------------- | :----------------- | :-------------------------- | :---------------- |
| **Phone Number**               | User Input     | Authentication & Identity | Account-Private     | `phone_identities` table | Encrypted at Rest     | Account lifetime                       | Purged on account delete | API Service             | Redacted (`+97798****567`) | Included in export | SMS OTP Vendor (Transitory) | Account Delete    |
| **Username**                   | User Input     | Public Handle             | Public              | `usernames` table        | Plaintext             | Allocated lifetime                     | Purged on account delete | Public                  | Logged safely              | Included in export | None                        | User editable     |
| **Display Name**               | User Input     | Profile UI                | Public              | `user_profiles` table    | Plaintext             | Account lifetime                       | Purged on account delete | Authenticated Users     | Logged safely              | Included in export | None                        | User editable     |
| **Device Public Prekeys**      | Mobile Client  | E2EE Session Setup        | Public Key Material | `device_key_bundles`     | Plaintext Public Keys | Active device lifetime                 | Purged on device unlink  | Authenticated Users     | Logged safely              | Excluded           | None                        | Unlink Device     |
| **Encrypted Message Envelope** | Mobile Client  | Messaging Delivery        | Encrypted Envelope  | `message_envelopes`      | Opaque Base64 E2EE    | Max 30d (undelivered) / 7d (delivered) | Automatic DB row purge   | Realtime Service        | Payload never logged       | Excluded           | None                        | Delete Message    |
| **Encrypted Media Attachment** | Mobile Client  | File Sharing              | Encrypted Blob      | S3 Bucket                | AES-256-GCM Blob      | 30 days                                | Purged from S3 bucket    | Authenticated Recipient | Object key logged          | Excluded           | None                        | Delete Attachment |
| **User Abuse Report Evidence** | Reporting User | Trust & Safety Review     | Admin-Restricted    | `reports` table          | Encrypted at Rest     | 90 days                                | Hard purge after review  | Trust & Safety Analysts | Evidence text never logged | Excluded           | None                        | Submit Report     |
| **Admin Audit Event**          | Admin Action   | Compliance Audit          | Operational Audit   | `admin_audit_events`     | Encrypted at Rest     | 7 years (Immutable)                    | Append-only (No delete)  | Security Engineers      | Masked parameters          | Excluded           | Regulators (Subpoena)       | None              |
