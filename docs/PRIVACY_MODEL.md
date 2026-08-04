# GuffSuff Privacy Architecture & Data Minimization Model

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Warning**: GuffSuff does not yet contain production end-to-end encryption and must not be marketed or represented as cryptographically secure until implementation, independent review, and release acceptance gates are completed.

---

## 1. Privacy Boundaries & Data Protection Tiers

1. **Message-Content Confidentiality**: End-to-end encryption ensures message text, voice recordings, and attachment files are encrypted on-device. Zero plaintext content is accessible to server operators or database administrators.
2. **Metadata Privacy**: Server retains minimal operational metadata necessary for packet routing and rate limiting. Metadata is purged according to strict retention schedules.
3. **Contact-Graph Privacy**: Phone number matching utilizes salted HMAC hashing in Stage A, with transition to Private Set Intersection (PSI) under evaluation for Stage B. Raw address books are never uploaded or stored.
4. **Notification Privacy**: Push notifications routed through FCM / APNs contain zero message text or media previews. Notifications convey opaque event triggers only (`SEC-MSG-001`).
5. **Device Privacy**: Identity keys and database encryption keys remain inside platform hardware enclaves (iOS Keychain / Android Keystore).
6. **Administrative Privacy**: Support and Trust & Safety agents operate under RBAC controls with zero access to private message contents or decryption keys (`SEC-ADMIN-001`).
