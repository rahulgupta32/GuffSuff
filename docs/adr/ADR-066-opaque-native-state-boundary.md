# ADR-066: Opaque Native State Boundary

- **Status**: Accepted
- **Date**: 2026-08-06

## Decision

All identity private keys, ratchet states, and MLS group states are held in native memory behind branded opaque handles (`OpaqueIdentityKeyHandle`, `OpaqueSessionStateHandle`, `OpaqueGroupStateHandle`). Private key bytes are never transferred to JavaScript or Dart runtimes.
