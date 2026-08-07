# ADR-042: OTP Challenge Verifier Storage

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Principal Security Architect, Backend Lead

## Context

Storing plain OTPs or plain SHA-256 hashes in database storage creates vulnerability to table leaks and offline brute-force attacks.

## Decision

1. OTP verifiers are stored as HMAC-SHA256 digests computed over `challenge_id:otp_code` using a versioned server-side pepper (`SERVER_PEPPER_V1`).
2. OTP verification is performed using `crypto.timingSafeEqual` in constant time.
3. Verification attempts increment atomically in SQL and challenges expire in 5 minutes (300 seconds). Plain OTP values are never stored or logged.
