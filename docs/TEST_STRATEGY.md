# GuffSuff Test Strategy & Quality Assurance Plan

> **Status**: Initial Draft (Phase 0 Bootstrap)

---

## Testing Pyramid

1. **Unit Tests**: Domain logic, E.164 Nepal phone normalization, crypto adapter contracts, localization.
2. **Integration Tests**: Repository layer, PostgreSQL schemas, Redis rate limiters, S3 presigned URL generators.
3. **End-to-End Tests**: Full flow registration, key package publishing, message delivery, attachment transfer, and device revocation.
4. **Security Tests**: SAST, dependency vulnerability scanning, secrets scanning (gitleaks), OWASP MASVS verification.
