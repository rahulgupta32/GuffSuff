# ADR-039: Least-Privilege Pinned CI Workflow Security

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Security Engineering Lead
- **Decision Status**: Proposed

## Context

GitHub Actions workflows with default write permissions or floating third-party action tags expose repositories to supply-chain injection attacks.

## Decision

All GitHub Actions workflows MUST set explicit least-privilege `permissions` blocks and pin third-party actions to full 40-character commit SHAs.
