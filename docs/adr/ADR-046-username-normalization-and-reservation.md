# ADR-046: Username Normalization and Reservation

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Product Lead, Security Architect

## Context

Usernames are public handles. Strict validation and case-insensitive uniqueness are required to prevent impersonation and race conditions during registration.

## Decision

1. Usernames must match `^[a-z0-9_]+$` (3–20 lowercase ASCII characters, numbers, and underscore).
2. Uniqueness is enforced on `username_canonical` via unique DB indexes.
3. Reservation changes enforce a 30-day change cooldown. Reserved system names are rejected.
