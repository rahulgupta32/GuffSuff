# ADR-049: Registration-Lock Hashing and Recovery Boundary

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Security Architect, Cryptography Lead

## Context
Registration-lock PINs protect against SIM swap attacks during re-registration. Plaintext storage or weak hashing compromises PIN secrecy.

## Decision
1. PINs must be 6 to 12 digits (8 recommended).
2. PINs are hashed using Argon2id with a versioned server-side pepper (`m=65536, t=3, p=4`). Plaintext PINs are never stored.
3. Verification attempts are tracked atomically (`registration_lock_attempts`). 5 failed attempts trigger a 30-minute lockout.
4. SMS-only bypass is strictly forbidden. Disabling or modifying PIN requires recent re-authentication and current PIN verification.
