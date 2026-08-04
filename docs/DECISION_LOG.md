# GuffSuff Architecture & Decision Log

This document records key architectural decisions, privacy models, technology assessments, and baseline security choices made throughout the lifecycle of GuffSuff.

---

## Log Summary

| ADR ID | Date | Title | Status | Authors / Approvers |
| :--- | :--- | :--- | :--- | :--- |
| **ADR-000** | 2026-08-05 | Monorepo Bootstrap & Security Foundations | Approved | Rahul Gupta (`@rahulgupta32`), AI Architect |

---

## ADR-000: Monorepo Bootstrap & Security Foundations

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Core Architecture Team

### Context
GuffSuff requires a clean, scalable, multi-platform monorepo supporting mobile clients (Android/iOS), administrative interfaces, real-time WebSocket communication servers, background job processing, and shared cryptography/domain packages.

### Decision
1. **Repository Structure**: Adopt a standardized monorepo structure separating `apps/`, `services/`, `packages/`, `infrastructure/`, and `docs/`.
2. **Monorepo Safety Controls**: Enforce `.gitignore`, `gitleaks` secret detection, and strict pre-commit hooks before committing any application code.
3. **Documentation-Driven Architecture**: Mandate initial creation and maintenance of core technical documents in `docs/` (`PRODUCT_REQUIREMENTS.md`, `SYSTEM_ARCHITECTURE.md`, `THREAT_MODEL.md`, `ENCRYPTION_ARCHITECTURE.md`, etc.) before starting feature code.
4. **Crypto Boundary**: Restrict cryptographic operations to `packages/crypto-adapter` to ensure zero custom cryptography in application layers.

### Consequences
- High clarity of module boundaries and dependencies.
- Zero credential / secret leak guarantee via enforced pre-commit scanning.
- Traceable evolution of all privacy and architectural choices.
