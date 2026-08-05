# GuffSuff Master Security Test Plan

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Traceability Rule**: Every security requirement in `docs/SECURITY_REQUIREMENTS.md` MUST map to an automated or manual test activity in this plan.

---

## 1. Security Testing Categories

### Static Security Testing (SAST & Linting)

- **TypeScript & ESLint**: Run `@typescript-eslint` rules blocking `eval`, unsafe casts, and unhandled promise rejections.
- **Dart Analyzer**: Run `dart analyze` with strict lints blocking unhandled async errors and raw SQL strings.
- **Secret Scanning**: Run `gitleaks` on pre-commit hooks and CI pipelines (`SEC-CI-001`).
- **IaC Scanning**: Run `checkov` / `tfsec` on Terraform manifests (`SEC-INFRA-001`).

### Dynamic Application Security Testing (DAST & Penetration Testing)

- **REST API Authorization**: Test for BOLA/IDOR by attempting cross-tenant record retrieval.
- **OTP Brute Force**: Automated test verifying lockout after 3 failed OTP attempts (`SEC-OTP-001`).
- **WebSocket Hijacking**: Test socket connection rejection without valid JWT handshake token (`SEC-WS-001`).
- **S3 Bucket Exposure**: Verification that unauthenticated GET requests to S3 return 403 Forbidden (`SEC-MEDIA-001`).

### Mobile Platform Penetration Testing

- **Binary Hardening**: Verify APK/AAB and IPA binary symbols, stack protection, and release signing.
- **Local Storage Inspection**: Hex dump analysis of SQLite database files on device to confirm SQLCipher at-rest encryption (`SEC-MOBILE-001`).
- **Clipboard & Screenshot Leakage**: Test window preview suppression and clipboard clearing.

### Cryptographic Verification Testing

- **Known-Answer Tests (KAT)**: Execute official test vectors supplied by the selected cryptographic protocol library (Signal Protocol / OpenMLS) after Phase 2 approval.
- **Ciphertext Corruption**: Verify that bit-flipped ciphertext payloads fail decryption cleanly without exposing stack traces.
