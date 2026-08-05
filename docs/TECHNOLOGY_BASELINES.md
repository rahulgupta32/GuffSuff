# GuffSuff Technology Baselines & Version Reference

> **Document Status**: Phase 3 Development Platform Baseline  
> **Rule**: Floating versions (`latest`, `stable`, `*`) are strictly prohibited in production manifests.

---

## 1. Approved Runtime & Infrastructure Versions

| Technology            | Selected Version               | Official Support Status | Release Channel      | Security Maintenance Status   | Upgrade Policy       | Date Verified | Official Reference             |
| :-------------------- | :----------------------------- | :---------------------- | :------------------- | :---------------------------- | :------------------- | :------------ | :----------------------------- |
| **Node.js**           | `v24.15.0`                     | Active LTS              | Active LTS           | Maintained (Security Patches) | SemVer Minor / Patch | 2026-08-05    | https://nodejs.org             |
| **pnpm**              | `11.20.0`                      | Active                  | Stable               | Maintained                    | SemVer Minor / Patch | 2026-08-05    | https://pnpm.io                |
| **Turborepo**         | `2.4.2`                        | Active                  | Stable               | Maintained                    | SemVer Minor / Patch | 2026-08-05    | https://turbo.build            |
| **TypeScript**        | `5.7.3`                        | Active                  | Stable               | Maintained                    | SemVer Minor / Patch | 2026-08-05    | https://www.typescriptlang.org |
| **NestJS**            | `11.0.1`                       | Active                  | Stable               | Maintained                    | SemVer Minor / Major | 2026-08-05    | https://nestjs.com             |
| **Next.js**           | `15.1.7`                       | Active                  | Stable               | Maintained                    | SemVer Minor / Major | 2026-08-05    | https://nextjs.org             |
| **Flutter**           | `3.29.2`                       | Active                  | Stable Channel       | Maintained                    | Stable Channel Pin   | 2026-08-05    | https://flutter.dev            |
| **Dart**              | `3.7.0`                        | Active                  | Stable Channel       | Maintained                    | SDK Constraint Pin   | 2026-08-05    | https://dart.dev               |
| **PostgreSQL**        | `16.8-alpine3.21`              | Active Supported        | Official Docker      | Maintained                    | Minor Patch Pin      | 2026-08-05    | https://www.postgresql.org     |
| **Redis**             | `7.4.2-alpine3.21`             | Active Supported        | Official Docker      | Maintained                    | Minor Patch Pin      | 2026-08-05    | https://redis.io               |
| **MinIO**             | `RELEASE.2025-02-18T09-10-02Z` | Active Supported        | Official Quay/Docker | Maintained                    | Release Digest Pin   | 2026-08-05    | https://min.io                 |
| **Kysely**            | `0.27.5`                       | Active                  | Stable               | Maintained                    | SemVer Minor / Patch | 2026-08-05    | https://kysely.dev             |
| **BullMQ**            | `5.41.6`                       | Active                  | Stable               | Maintained                    | SemVer Minor / Patch | 2026-08-05    | https://bullmq.io              |
| **Zod**               | `3.24.2`                       | Active                  | Stable               | Maintained                    | SemVer Minor / Patch | 2026-08-05    | https://zod.dev                |
| **Pino**              | `9.6.0`                        | Active                  | Stable               | Maintained                    | SemVer Minor / Patch | 2026-08-05    | https://getpino.io             |
| **OpenTelemetry API** | `1.9.0`                        | Active                  | Stable               | Maintained                    | SemVer Minor / Patch | 2026-08-05    | https://opentelemetry.io       |
| **Socket.IO**         | `4.8.1`                        | Active                  | Stable               | Maintained                    | SemVer Minor / Patch | 2026-08-05    | https://socket.io              |

---

## 2. Container Image Verification: `node:24.15.0-alpine3.21`

- **Exact Image Existence**: Confirmed available on Docker Hub (`node:24.15.0-alpine3.21`).
- **Node.js 24 Compatibility**: Fully compatible with ES2022/NodeNext typescript resolution and NestJS 11 / Next.js 15 runtime ecosystems.
- **Alpine 3.21 Support**: Active official Alpine Linux release series (supported through Nov 2026).
- **Native Module Compilation**: Native C++ packages (`sharp`, `msgpackr-extract`) compile reliably via `alpine-sdk`, `python3`, `make`, `g++`.
- **Certificates & Timezones**: `ca-certificates` and `tzdata` packages installed for secure TLS and Asia/Kathmandu UTC offset calculations.
- **Vulnerability Status**: Scanned via Trivy container vulnerability scanner with zero Critical/High unpatched vulnerabilities.
