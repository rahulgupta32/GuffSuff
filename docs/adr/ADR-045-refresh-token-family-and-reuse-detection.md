# ADR-045: Refresh-Token Family and Reuse Detection

- **Status**: Approved Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Principal Security Architect, Backend Lead

## Context
Stolen refresh tokens present a severe compromise risk. Reuse detection is required to identify token theft immediately and mitigate session hijacking.

## Decision
1. Group refresh tokens into token families (`refresh_token_families`). Each rotation creates a child `refresh_tokens` instance linked to its parent.
2. Allow a 10-second grace window for concurrent requests using a recently rotated parent token.
3. If an already-rotated refresh token is reused outside the grace window, mark the token family as compromised, revoke all active sessions/devices in that family, and trigger a high-severity security event.
