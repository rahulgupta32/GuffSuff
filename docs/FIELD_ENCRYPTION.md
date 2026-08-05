# Server-Side Field Encryption Architecture & Policy

> **Document Status**: Production Security Specification  
> **Target Package**: `services/api` (`PhoneNumberService`) & `packages/crypto-adapter`

---

## 1. Scope & Isolation

Application-level field encryption is applied strictly to sensitive user identity fields (e.g. phone numbers). It is completely separate from message content encryption (Signal Protocol E2EE in Phase 6).

- **Algorithm**: `AES-256-GCM` (authenticated encryption with associated data via Node.js standard `crypto` module).
- **Key Source**: Loaded from `PHONE_ENCRYPTION_SECRET` (32-byte secret key).
- **HMAC Blind Index**: Loaded from separate key `PHONE_HMAC_PEPPER` (32-byte secret key).
- **Nonce Generation**: Fresh 12-byte (96-bit) cryptographically random IV generated per encryption using `crypto.randomBytes(12)`.
- **Envelope Format**: `v1:iv_hex:auth_tag_hex:ciphertext_hex`

---

## 2. Security Rules & Invariants

1. **Nonce Uniqueness**: Nonces are generated using `crypto.randomBytes(12)` for every single encryption. Nonce derivation or reuse from user IDs, phone numbers, timestamps, row IDs, or blind indexes is strictly prohibited.
2. **Key Versioning**: Envelope prefix `v1:` identifies key version.
3. **Authentication Tag Validation**: AES-256-GCM authentication tags (16 bytes) are validated before returning plaintext. Failures fail closed immediately.
4. **Key Separation**: Distinct keys are used for:
   - Phone field encryption (`PHONE_ENCRYPTION_SECRET`)
   - Phone HMAC blind index (`PHONE_HMAC_PEPPER`)
   - OTP verifier pepper (`OTP_VERIFIER_PEPPER_V1`)
   - Registration lock PIN pepper (`REGISTRATION_LOCK_PEPPER`)
   - Access token JWT signing (`JWT_ACCESS_SECRET`)
5. **No Plaintext Logging**: Decrypted phone values are masked (`+97798****1234`) in operational logs.
6. **Key Rotation & Migration**: Supports dual-read (attempt current version key first, fallback to previous version key if tag validation fails) and single-write (always write using current version key). Controlled background worker handles staged re-encryption.
