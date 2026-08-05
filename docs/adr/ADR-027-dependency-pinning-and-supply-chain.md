# ADR-027: Dependency Pinning and Supply Chain Controls

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: DevSecOps Lead
- **Decision Status**: Proposed

## Context

Unpinned dependencies or floating CI action tags allow upstream package compromise (supply-chain attack) to inject malicious code into release builds.

## Decision

All package lockfiles MUST be committed to Git. GitHub Actions MUST be pinned to full 40-character commit SHAs (`SEC-CI-001`, `SEC-DEPENDENCY-001`).
