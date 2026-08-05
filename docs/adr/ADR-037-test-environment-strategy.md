# ADR-037: Isolated Test Environment & Mock Strategy

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: QA Lead, Security Lead
- **Decision Status**: Proposed

## Context

Automated tests require isolated, reproducible environments that use fictional test data and mock external hardware/network dependencies safely.

## Decision

Unit and integration tests run against isolated ephemeral Docker databases and emulators. Test data MUST use fictional reserved identifiers (e.g. `+9779800000000`). Production mock crypto is strictly forbidden.
