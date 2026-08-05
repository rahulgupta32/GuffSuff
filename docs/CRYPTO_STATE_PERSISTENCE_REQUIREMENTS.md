# Cryptographic State Persistence Requirements

> **Document Status**: Durable Cryptographic Storage Standard

---

## 1. Required Persistence Entities

1. **Identity Records**: Public & private identity keypairs (`identity_key_pub`, `identity_key_priv`).
2. **Prekey Store**: Signed prekeys (`signed_prekey_id`, signatures) and One-Time Prekeys (OTPs).
3. **Session Records**: Active pairwise session states, ratchet keys, and root keys.
4. **Group State (MLS)**: Group context, epoch secrets, member public keys, and TreeKEM node states.
5. **Replay & Skip Keys**: Out-of-order message keys held temporarily for delayed message decryption.

---

## 2. Mandatory Storage Invariants

- **Atomic Transactions**: All session ratchet updates and message key deletions MUST occur within atomic database transactions to prevent double-use or state desynchronization.
- **Hardware Master Encryption**: Local SQLite database keys derived via Argon2id and stored in Android KeyStore (TEE / StrongBox) or iOS Keychain (Secure Enclave).
- **Crash Consistency**: Corrupted state files on unexpected app termination must trigger secure fallback re-keying rather than plaintext fallback.
- **Zero Production Schema Migrations**: No database schema changes are authorized during initial compatibility spikes.
