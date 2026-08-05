# ADR-021: Encrypted Attachment Media Key Distribution

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Mobile Architect, Backend Lead
- **Decision Status**: Proposed

## Context

Storing unencrypted media attachments on cloud object storage (S3) allows cloud operators or unauthorized buckets access to private user media.

## Decision

All media attachments MUST be encrypted locally on device via AES-256-GCM. The random media key $K_{media}$ is transferred exclusively inside E2EE message envelopes.
