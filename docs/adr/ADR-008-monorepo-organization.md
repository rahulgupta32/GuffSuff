# ADR-008: Monorepo Organization and Package Isolation

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

GuffSuff involves multiple execution targets (mobile app, admin web console, backend REST API, realtime gateway, background worker) that share API contracts, design tokens, cryptographic adapters, and localization strings.

---

## Decision

We maintain a single **GuffSuff Monorepo** organized as:

- `apps/`: Target applications (`mobile`, `admin`).
- `services/`: Backend microservices / entry points (`api`, `realtime`, `worker`).
- `packages/`: Shared packages (`contracts`, `crypto-adapter`, `design-system`, `localization`, `shared-config`, `test-utils`).
- `infrastructure/`: Infrastructure-as-code and container manifests (`docker`, `terraform`, `kubernetes`, `monitoring`).
- `docs/`: Technical documentation, ADRs, diagrams, and runbooks.

---

## Tooling Standards

- npm / pnpm workspaces for Node.js services and TypeScript packages.
- Flutter pub workspace configuration for mobile app and Dart crypto bindings.
