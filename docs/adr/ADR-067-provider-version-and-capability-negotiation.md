# ADR-067: Provider Version and Capability Negotiation

- **Status**: Accepted
- **Date**: 2026-08-06

## Decision

Cryptographic providers dynamically report capabilities and supported protocol versions via `queryCapabilities()`. Applications verify version compatibility before initiating cryptographic sessions.
