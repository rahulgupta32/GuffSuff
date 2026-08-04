# ADR-022: Device Revocation and Prekey Purging

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Security Engineering Lead
- **Decision Status**: Proposed

## Context
Stolen or lost devices can continue receiving encrypted messages unless their public prekeys are purged from server key directories.

## Decision
Invoking device revocation API instantly marks device status `REVOKED`, purges published public prekey bundles, and forces immediate WebSocket disconnect.
