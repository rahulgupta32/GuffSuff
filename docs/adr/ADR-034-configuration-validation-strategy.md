# ADR-034: Fail-Closed Environment Configuration Validation Strategy

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: DevSecOps Lead, Security Engineer
- **Decision Status**: Proposed

## Context

Services starting with missing or invalid production environment variables pose severe security and operational risks.

## Decision

All services MUST validate configuration environment variables at startup using strict Zod schemas. Services MUST fail startup immediately if required production variables are absent or insecure defaults are detected.
