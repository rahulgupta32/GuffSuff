# ADR-030: Disappearing Messages & Envelope Purge Retention

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Privacy Architect, Backend Lead
- **Decision Status**: Proposed

## Context
Retaining delivered message envelopes on server databases indefinitely increases server storage costs and data breach liability.

## Decision
Undelivered envelopes are purged after 30 days. Delivered envelope retention (proposed 7 days) is marked `Under evaluation` pending final multi-device history sync architecture.
