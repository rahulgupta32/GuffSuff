# GuffSuff Privacy Model & Data Minimization

> **Status**: Initial Draft (Phase 0 Bootstrap)

---

## Data Classification Baseline

1. **Public**: Username, Avatar thumbnail reference (if public setting enabled).
2. **Account-Private**: Normalized phone number (restricted DB table), user privacy settings.
3. **Operational**: Device registration timestamp, push notification token (opaque).
4. **Encrypted Content**: Opaque message envelopes and attachment ciphertexts.
5. **Forbidden Server Data**: Plaintext message body, unencrypted media, private keys, raw address books, raw OTP codes.
