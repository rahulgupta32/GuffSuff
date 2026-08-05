# GuffSuff Selected Phase 3 Technology Baselines & Version Reference

> **Document Status**: Phase 3 Development Platform Baseline  
> **Rule**: Floating versions (`latest`, `stable`, `*`) are strictly prohibited in production manifests.

---

## 1. Selected Phase 3 Technology Baselines

| Technology            | Selected Version               | Official Release Source        | Support Status   | Date Verified | Compatibility Test Status                            | Upgrade Strategy     |
| :-------------------- | :----------------------------- | :----------------------------- | :--------------- | :------------ | :--------------------------------------------------- | :------------------- |
| **Node.js**           | `v24.15.0`                     | https://nodejs.org             | Active LTS       | 2026-08-05    | **PASSED** (Full monorepo build & test suite)        | SemVer Minor / Patch |
| **pnpm**              | `11.20.0`                      | https://pnpm.io                | Active           | 2026-08-05    | **PASSED** (Workspace lockfile validation)           | SemVer Minor / Patch |
| **Turborepo**         | `2.4.2`                        | https://turbo.build            | Active           | 2026-08-05    | **PASSED** (Parallel pipeline build orchestration)   | SemVer Minor / Patch |
| **TypeScript**        | `5.7.3`                        | https://www.typescriptlang.org | Active           | 2026-08-05    | **PASSED** (Strict typechecking across 18 packages)  | SemVer Minor / Patch |
| **NestJS**            | `11.0.1`                       | https://nestjs.com             | Active           | 2026-08-05    | **PASSED** (API and Realtime service builds)         | SemVer Minor / Major |
| **Next.js**           | `15.1.7`                       | https://nextjs.org             | Active           | 2026-08-05    | **PASSED** (Admin web app production bundle build)   | SemVer Minor / Major |
| **Flutter**           | `3.29.2`                       | https://flutter.dev            | Stable Channel   | 2026-08-05    | **PASSED IN CI** (Dart format, analyze, unit test)   | Stable Channel Pin   |
| **Dart**              | `3.7.0`                        | https://dart.dev               | Stable Channel   | 2026-08-05    | **PASSED IN CI** (Devanagari ARB widget tests)       | SDK Constraint Pin   |
| **PostgreSQL**        | `16.8-alpine3.21`              | https://www.postgresql.org     | Active Supported | 2026-08-05    | **PASSED IN CI** (Compose integration & Kysely pool) | Minor Patch Pin      |
| **Redis**             | `7.4.2-alpine3.21`             | https://redis.io               | Active Supported | 2026-08-05    | **PASSED IN CI** (Key prefixing & BullMQ worker)     | Minor Patch Pin      |
| **MinIO**             | `RELEASE.2025-02-18T09-10-02Z` | https://min.io                 | Active Supported | 2026-08-05    | **PASSED IN CI** (Path-style S3 client integration)  | Release Digest Pin   |
| **Kysely**            | `0.27.5`                       | https://kysely.dev             | Active           | 2026-08-05    | **PASSED** (Type-safe SQL migration suite)           | SemVer Minor / Patch |
| **BullMQ**            | `5.41.6`                       | https://bullmq.io              | Active           | 2026-08-05    | **PASSED** (Health check queue processing)           | SemVer Minor / Patch |
| **Zod**               | `3.24.2`                       | https://zod.dev                | Active           | 2026-08-05    | **PASSED** (Fail-closed env schema unit tests)       | SemVer Minor / Patch |
| **Pino**              | `9.6.0`                        | https://getpino.io             | Active           | 2026-08-05    | **PASSED** (Structured JSON logger PII masking)      | SemVer Minor / Patch |
| **OpenTelemetry API** | `1.9.0`                        | https://opentelemetry.io       | Active           | 2026-08-05    | **PASSED** (Tracing & metrics initialization)        | SemVer Minor / Patch |
| **Socket.IO**         | `4.8.1`                        | https://socket.io              | Active           | 2026-08-05    | **PASSED** (Realtime WebSocket handshake rejection)  | SemVer Minor / Patch |

---

## 2. Base Container Verification: `node:24.15.0-alpine3.21`

- **Exact Image Existence**: Confirmed available on Docker Hub (`node:24.15.0-alpine3.21`).
- **Node.js 24 Compatibility**: Fully compatible with ES2022/NodeNext typescript resolution and NestJS 11 / Next.js 15 runtime ecosystems.
- **Alpine 3.21 Support**: Active official Alpine Linux release series (supported through Nov 2026).
- **Native Module Compilation**: Native C++ packages (`sharp`, `msgpackr-extract`) compile reliably via `alpine-sdk`, `python3`, `make`, `g++`.
- **Certificates & Timezones**: `ca-certificates` and `tzdata` packages installed for secure TLS and Asia/Kathmandu UTC offset calculations.
- **Vulnerability Status**: Scanned via Trivy container vulnerability scanner with zero Critical/High unpatched vulnerabilities.
