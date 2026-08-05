# GuffSuff Test Environments & Fictional Data Strategy

> **Document Status**: Phase 3 Development Platform Baseline

---

## 1. Test Environment Isolation

Automated tests execute against isolated local Docker containers or ephemeral CI environments (`ADR-037`).

## 2. Fictional Test Data Policy

Real subscriber identities or live phone numbers MUST NOT be used in test suites. Test suites use reserved opaque identifiers:

- **Phone Number**: `+9779800000000` (Reserved non-subscriber test number in `@guffsuff/test-utils`).
- **Device ID**: `00000000-0000-7000-8000-000000000001`.
- **User ID**: `00000000-0000-7000-8000-000000000002`.
