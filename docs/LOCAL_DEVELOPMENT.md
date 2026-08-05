# GuffSuff Local Development Environment Guide

> **Document Status**: Phase 3 Development Platform Baseline

---

## 1. Local Development Architecture

The GuffSuff local environment executes via Docker Compose for infrastructure dependencies (PostgreSQL 16, Redis 7.2, MinIO S3 emulator, OpenTelemetry Collector) while backend microservices (`services/*`) and administrative web apps (`apps/admin`) run in pnpm workspace hot-reload mode.

---

## 2. Command Reference

- `make setup`: Install node_modules via frozen lockfile.
- `make dev`: Spin up Docker infrastructure and start all services in watch mode.
- `make test`: Run workspace unit and safety tests.
- `make lint`: Execute ESLint across all projects.
- `make typecheck`: Run TypeScript compiler checks across workspaces.
- `make build`: Compile static production bundles and NestJS services.
- `make security-scan`: Run gitleaks and mock crypto boundary scanner.
- `make db-migrate`: Run database schema migrations.
- `make db-reset-local`: Reset local development PostgreSQL database (restricted to local environment).
