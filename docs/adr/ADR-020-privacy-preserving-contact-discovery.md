# ADR-020: Privacy-Preserving Contact Discovery Staging

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Privacy Architect
- **Decision Status**: Proposed

## Context

Uploading unhashed or raw phone address books violates user privacy. Plain SHA-256 hashing is vulnerable to dictionary attacks over small number spaces (+977).

## Decision

Adopt a two-stage strategy: Stage A uses client-side HMAC-SHA256 with daily salts for MVP; Stage B evaluates Private Set Intersection (PSI / OPRF) for post-MVP releases.
