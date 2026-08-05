# ADR-029: Local Mobile Database At-Rest Encryption via SQLCipher

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Mobile Architect, Security Lead
- **Decision Status**: Proposed

## Context

Local SQLite database stores message history and user profile data on mobile devices. Standard SQLite stores data in plaintext on device flash storage.

## Decision

Local database MUST use SQLCipher for at-rest encryption. Drift provides Dart ORM query abstractions, while encryption keys are sourced from platform secure storage (`SEC-MOBILE-001`).
