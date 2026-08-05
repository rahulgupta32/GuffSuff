# ADR-050: Identity Security-Event Model

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Security Architect, Backend Lead

## Context
Security events inform users of critical account activities (new device, session revocation, token reuse). Internal risk scores and abuse flags must not leak to clients.

## Decision
1. Security events store user-safe description keys (`user_description_key`) and safe device context (`device_context_json`).
2. Internal risk metrics and abuse signals are isolated in `internal_metadata_json`.
3. Client API projections strictly omit `internal_metadata_json` from all response DTOs.
