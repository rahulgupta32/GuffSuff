# ADR-018: Ephemeral Access Tokens & Device-Bound Refresh Tokens

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Backend API Lead, Security Lead
- **Decision Status**: Proposed

## Context
Long-lived bearer tokens expose users to prolonged unauthorized access if hijacked from network traffic or local client memory.

## Decision
Enforce 15-minute access JWTs coupled with 30-day refresh tokens bound to physical `deviceId`. Refresh tokens are rotated on every use with automatic reuse detection.
