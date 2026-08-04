# ADR-024: Administrative WebAuthn MFA and Four-Eyes Approval

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Admin Lead, Security Lead
- **Decision Status**: Proposed

## Context
Administrative accounts with elevated permissions represent high-value targets for credential compromise or insider threats.

## Decision
Enforce mandatory WebAuthn/TOTP MFA for all admin accounts. High-impact administrative actions (global bans, bulk exports) require explicit approval from two independent administrators (`SEC-ADMIN-001`).
