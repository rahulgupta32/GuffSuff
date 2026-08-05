# Cryptographic Test Vector & Interoperability Plan

> **Document Status**: Test Vectors & Cross-Platform Validation Specification

---

## 1. Official Test Vectors

1. **Double Ratchet**: Standard published Signal Double Ratchet test vectors for DH ratchet steps, symmetric key chain steps, and out-of-order message handling.
2. **X3DH / PQX3DH**: Test vectors for prekey bundle generation, ephemeral key exchange, and shared secret derivation.
3. **AES-256-GCM Payload Encryption**: Known Answer Tests (KAT) for 12-byte IV, 16-byte auth tag, and ciphertext verification.
4. **Argon2id Key Derivation**: NIST / IETF Argon2id test vectors for registration lock and local database passphrase derivation.

---

## 2. Interoperability Suite

Cross-platform automated suite validating identical ciphertext decryption across Node.js backend, Flutter Dart FFI, Android Kotlin, and iOS Swift native test harnesses.
