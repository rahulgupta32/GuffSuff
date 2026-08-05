# ADR-040: Build-Flavor and Environment Isolation

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Mobile Architect, Backend Lead
- **Decision Status**: Proposed

## Context

Mixing development status indicators or development backend endpoints into production client builds risks leaking test modes to end users.

## Decision

Mobile and web applications enforce distinct build flavors (`development`, `staging`, `production`). Development builds visibly display a `Development build — not for production use` watermark banner. Production flavor builds fail if development flags are present.
