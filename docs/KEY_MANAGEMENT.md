# GuffSuff Key Management Specification

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Rule**: No key MAY be used for multiple security purposes. Separation of duties is strictly enforced.

---

## 1. Key Lifecycle & Inventory Matrix

| Key / Secret Type                            | Owner           | Purpose                       | Generation Location            | Storage Location                     | Access Policy                   | Rotation Trigger / Frequency                     | Revocation & Incident Procedure                          |
| :------------------------------------------- | :-------------- | :---------------------------- | :----------------------------- | :----------------------------------- | :------------------------------ | :----------------------------------------------- | :------------------------------------------------------- |
| **Device Identity Key (Ed25519/Curve25519)** | Mobile Device   | Device E2EE Identity          | Mobile Device Secure Enclave   | iOS Keychain / Android Keystore      | App sandboxed access only       | Never rotated (Bound to device lifetime)         | Immediate device revocation via API (`SEC-DEVICE-001`).  |
| **Signed Prekey**                            | Mobile Device   | Session Setup                 | Mobile Device                  | Hardware Keystore                    | Publicly published to server    | Rotated every **7 days**                         | Delete old signed prekey; publish new signed prekey.     |
| **One-Time Prekeys (OTPs)**                  | Mobile Device   | Initial Session Setup         | Mobile Device                  | Consumed on server, stored on device | Consumed once by sender         | Replenished when active pool drops below 20 keys | Server deletes depleted keys automatically.              |
| **Database Encryption Key (SQLCipher)**      | Mobile Device   | Local SQLite At-Rest Key      | Mobile Device Hardware Enclave | iOS Keychain / Android Keystore      | Flutter app local DB process    | Rotated during app reinstall or security breach  | Purge local SQLite DB & clear Keychain entry.            |
| **JWT Access Signing Key**                   | API Gateway     | REST JWT Authentication       | Server Secrets Manager         | API Gateway RAM                      | `services/api` process only     | Rotated every **90 days**                        | Force refresh token invalidation in Redis.               |
| **Refresh Token Hash Key**                   | API Gateway     | Refresh Token HMAC            | Server Secrets Manager         | API Gateway RAM                      | `services/api` process only     | Rotated annually                                 | Flush active session hashes in PostgreSQL.               |
| **S3 Media Encryption Master Key**           | S3 Bucket       | Presigned Media Authorization | Cloud KMS                      | Cloud Key Management Service         | KMS IAM service role            | Rotated annually                                 | KMS key rotation; old keys retained for decryption.      |
| **SMS OTP Hash Salt Key**                    | API Gateway     | Argon2id OTP Salting          | Server Secrets Manager         | API Gateway RAM                      | `services/api` process only     | Rotated every **30 days**                        | Flush active OTP keys in Redis.                          |
| **TLS Certificates**                         | DevSecOps       | HTTPS / WSS Encryption        | Let's Encrypt / Cloud CA       | WAF / Reverse Proxy                  | Reverse proxy process           | Automated rotation every **60 days**             | Emergency certificate revocation & re-issuance via ACME. |
| **Code Signing Keys (APK/IPA)**              | Release Manager | Mobile Binary Signing         | Hardware Security Module (HSM) | Encrypted CI HSM Vault               | Release CI pipeline runner only | Rotated upon expiration or compromise            | Revoke provisioning profile & issue app update.          |
