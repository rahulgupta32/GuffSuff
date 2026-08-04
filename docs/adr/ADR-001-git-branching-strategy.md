# ADR-001: Git Branching and Protection Strategy

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

To ensure production stability, auditability, and zero-trust security, GuffSuff requires a disciplined Git branching strategy. Direct commits to production branches without automated CI testing, secret scanning, and peer review introduce severe risks of secret leaks, regressions, and broken builds.

---

## Decision

We adopt a **Trunk-Based Protected Development Workflow**:

1. **Protected Main Branch**: `main` is the sole protected, production-ready branch. Direct pushes to `main` are strictly prohibited following the initial repository bootstrap. Force pushes and branch deletions on `main` are blocked.
2. **Short-Lived Phase/Topic Branches**: All new work, architecture phases, features, bug fixes, and security patches must be developed on short-lived topic branches (e.g., `docs/product-architecture`, `feat/<name>`, `fix/<name>`, `security/<name>`).
3. **Pull Request Gateways**: Code must be integrated into `main` via Pull Requests. Every PR requires:
   - At least one code review approval from an authorized code owner.
   - Resolution of all PR conversation threads.
   - Passing status on all required CI checks (linting, SAST, secret scanning, unit/integration tests).
4. **Release Strategy**: Production releases will utilize immutable Git tags (`vX.Y.Z`) and optional short-lived release branches (`release/vX.Y.Z`) if hotfixes are necessary.
5. **No Long-Lived Develop Branch**: To avoid branch drift and complex merge debt, no long-lived `develop` branch will be maintained during initial MVP phases.

---

## Alternatives Considered

- **GitFlow**: Rejected due to high overhead of managing long-lived `develop`, `release`, and `hotfix` branches simultaneously for an MVP team.
- **Unprotected Direct-to-Main**: Rejected due to unacceptable security and regression risks.

---

## Consequences & Implications

- **Security**: All commits reaching `main` must pass automated secret scanning (`gitleaks`) and SAST scans.
- **Operational**: Requires GitHub branch protection settings configured on `main` by the repository owner.
- **Traceability**: Conventional commit messages (`feat:`, `fix:`, `security:`, `docs:`, `chore:`) provide an immutable audit log.

---

## Revisit Conditions

Re-evaluate when the core engineering team expands beyond 10 engineers or when multiple simultaneous LTS releases must be supported.
