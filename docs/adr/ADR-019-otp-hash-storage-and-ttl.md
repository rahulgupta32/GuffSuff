# ADR-019: OTP Hashing with Argon2id and Redis TTL

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Security Engineering Lead
- **Decision Status**: Proposed

## Context
Plaintext OTP codes stored in cache layers allow unauthorized authentication if the Redis cluster is inspected or breached.

## Decision
Store only `Argon2id(OTP + Salt)` in Redis with a 5-minute TTL. Raw OTPs are never stored or logged in backend infrastructure.
