# GuffSuff Security Open Questions & Pending Decisions

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Status Tag**: All entries are `UNDER EVALUATION`.

---

## Security Decision Matrix

| # | Security Question / Decision Area | Evaluation Candidates | Proposed Recommendation | Security Impact & Status |
| :--- | :--- | :--- | :--- | :--- |
| **1** | Production E2EE Protocol Engine | Signal Protocol (`libsignal`) vs Messaging Layer Security (MLS / RFC 9420) | Evaluate Signal Protocol for 1-to-1 and MLS for efficient group fan-out | `UNDER EVALUATION` |
| **2** | OTP Delivery Gateway Selection | Sparrow SMS vs Twilio vs Multi-Vendor SMS Router | Implement multi-vendor provider abstraction with failover & signature verification | `UNDER EVALUATION` |
| **3** | Mobile Local Database Encryption | SQLCipher vs SQLite3 Encryption Extension (SEE) | SQLCipher integration via Flutter FFI bindings with keys from Keystore/Keychain | `UNDER EVALUATION` |
| **4** | Privacy-Preserving Contact Discovery | Salted HMAC (Stage A) vs Private Set Intersection (PSI / Stage B) | Stage A for MVP launch with strict rate limits; benchmark PSI for post-MVP | `UNDER EVALUATION` |
| **5** | Passkey / WebAuthn Support | Passwordless WebAuthn vs Standard SMS OTP | Support WebAuthn for Admin Console MFA; evaluate Passkeys for mobile secondary recovery | `UNDER EVALUATION` |
| **6** | Signed Prekey Rotation Interval | 7 Days vs 14 Days vs 30 Days | 7-day signed prekey rotation to limit compromise window | `UNDER EVALUATION` |
| **7** | Outbound Message Rate Limiting | 30 msgs/min vs 60 msgs/min vs Adaptive Behavioral | Adaptive sliding window rate limiting based on account age and recipient relationship | `UNDER EVALUATION` |
| **8** | Root / Jailbreak Action Policy | Block app execution vs Display warning vs Restrict local storage | Display security warning banner & disable unencrypted local backup; do not hard-block app | `UNDER EVALUATION` |
| **9** | Admin Four-Eyes Approval Policy | Global configuration vs Account bans vs Bulk exports | Require two independent administrator approvals for bulk suspensions & log exports | `UNDER EVALUATION` |
| **10**| Disappearing Message Purge Schedule | 24 Hours vs 7 Days vs 90 Days | Configurable per chat; client background job purges local database records upon expiration | `UNDER EVALUATION` |
