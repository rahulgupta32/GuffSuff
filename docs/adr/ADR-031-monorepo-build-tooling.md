# ADR-031: Monorepo Build Tooling and Workspace Strategy

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Architect, Lead DevSecOps Engineer
- **Decision Status**: Proposed

## Context

GuffSuff requires a unified monorepo structure housing backend service applications, administrative web app, mobile app, and shared packages with fast, deterministic builds and single lockfile dependency management.

## Decision

We adopt **pnpm Workspaces with Turborepo** (`turbo`) for build orchestration and task caching.

- **Package Manager**: `pnpm` (single root lockfile `pnpm-lock.yaml`).
- **Build Orchestrator**: `turbo` (task graph caching for linting, typechecking, testing, and building).
- **Security Rule**: Secrets, environment credentials, and private keys MUST NOT be cached by Turborepo (`turbo.json` outputs allowlist).
