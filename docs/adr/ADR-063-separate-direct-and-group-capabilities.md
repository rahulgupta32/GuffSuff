# ADR-063: Separate Direct and Group Provider Capability Families

- **Status**: Accepted
- **Date**: 2026-08-06

## Decision

Cryptographic capability negotiation decouples `DIRECT_MESSAGE_PROVIDER` (Track A) and `GROUP_MESSAGE_PROVIDER` (Track B) into separate capability queries. A provider may support one, both, or neither family without requiring a unified monolith implementation.
