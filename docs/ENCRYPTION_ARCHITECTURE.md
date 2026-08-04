# GuffSuff Encryption Architecture

> **Status**: Initial Draft (Phase 0 Bootstrap)  
> **Crypto Abstraction Package**: `packages/crypto-adapter`

---

## Cryptographic Abstraction Boundary

All cryptographic operations (session establishment, key generation, payload encryption, attachment key wrapping) MUST strictly interface through `packages/crypto-adapter`.

### Abstraction Driver Interfaces
- `ICryptoAdapter`: Core encryption/decryption interface.
- `MockCryptoAdapter`: Non-production mock adapter (enabled during Phase 5, strictly forbidden in Phase 6+).
- `ProductionCryptoAdapter`: Audited E2EE implementation (Signal Protocol / MLS evaluated in Phase 2/6).

### Rules
1. Server NEVER possesses private device keys or message/attachment decryption keys.
2. Push notifications contain OPAQUE event IDs only (zero plaintext or preview snippet).
3. Local device database must be encrypted at rest (SQLCipher / Drift encryption).
