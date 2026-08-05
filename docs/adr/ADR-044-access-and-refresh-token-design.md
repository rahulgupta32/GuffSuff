# ADR-044: Access and Refresh-Token Design

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Backend Lead, Security Architect

## Context
Short-lived access tokens provide stateless API authorization, while refresh tokens allow continuous session maintainability across application restarts.

## Decision
1. Access tokens are short-lived (15 minutes) JWTs signed with secret key containing `session_id`, `user_id`, `device_id`, and `session_version`. Secrets are never stored.
2. API Gateway & Guards validate token signature and check session status/version authoritatively in Redis/PostgreSQL.
3. Refresh tokens are long-lived (30 days) opaque random strings. Only secure verifier hashes are stored in the database.
