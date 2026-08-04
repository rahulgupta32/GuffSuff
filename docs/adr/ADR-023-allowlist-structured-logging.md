# ADR-023: Allowlist Structured JSON Logging

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: DevSecOps Lead, Security Engineer
- **Decision Status**: Proposed

## Context
Default loggers often leak authorization headers, tokens, raw phone numbers, or exception parameters to log aggregators.

## Decision
All services MUST output structured JSON logs filtered through an explicit allowlist schema (`SEC-LOG-001`). Credentials, keys, and message text are strictly prohibited from log streams.
