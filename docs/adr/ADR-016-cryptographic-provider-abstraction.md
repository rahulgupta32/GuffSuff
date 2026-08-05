# ADR-016: Cryptographic Provider Abstraction via ICryptoAdapter

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Security Architect, Lead Mobile Engineer
- **Decision Status**: Proposed

## Context
Directly coupling application features to a specific cryptographic library increases refactoring risk when migrating protocols (e.g. from Signal Protocol to MLS or Post-Quantum hybrid algorithms).

## Decision
All application code MUST interact exclusively with `ICryptoAdapter` in `packages/crypto-adapter`. Zero raw cryptographic primitive calls are permitted in feature components.
