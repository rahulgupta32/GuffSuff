# GuffSuff Dependency Inventory & Vulnerability Audit

> **Document Status**: Phase 3 Development Platform Baseline  
> **Audited Date**: 2026-08-05

---

## 1. Workspace Direct Dependencies

| Package / Application      | Dependency Name      | Version   | Purpose                           | Approved License |
| :------------------------- | :------------------- | :-------- | :-------------------------------- | :--------------- |
| `guffsuff-monorepo`        | `turbo`              | `2.4.2`   | Monorepo build orchestrator       | MIT              |
| `guffsuff-monorepo`        | `typescript`         | `5.7.3`   | TypeScript compiler               | Apache-2.0       |
| `@guffsuff/contracts`      | `zod`                | `3.24.2`  | Runtime schema validation         | MIT              |
| `@guffsuff/logger`         | `pino`               | `9.6.0`   | Structured JSON logger            | MIT              |
| `@guffsuff/observability`  | `@opentelemetry/api` | `1.9.0`   | OpenTelemetry tracing API         | Apache-2.0       |
| `@guffsuff/database`       | `pg`                 | `8.13.1`  | PostgreSQL client                 | MIT              |
| `@guffsuff/queue`          | `bullmq`             | `5.41.6`  | Redis queue manager               | MIT              |
| `@guffsuff/object-storage` | `@aws-sdk/client-s3` | `3.750.0` | S3 API client                     | Apache-2.0       |
| `@guffsuff/api`            | `@nestjs/core`       | `11.0.1`  | NestJS REST framework             | MIT              |
| `@guffsuff/realtime`       | `socket.io`          | `4.8.1`   | Realtime WebSocket server         | MIT              |
| `@guffsuff/admin`          | `next`               | `15.1.7`  | Next.js web application framework | MIT              |

---

## 2. Dependency Vulnerability Audit Report

| Package               | Installed Version | Severity | Advisory ID / Context                                           | Fixed Version | Remediation Decision                                                                  |
| :-------------------- | :---------------- | :------- | :-------------------------------------------------------------- | :------------ | :------------------------------------------------------------------------------------ |
| `postcss`             | `8.4.31`          | High     | GHSA-r28c-9q8g-f849 (Subdependency of Next.js 15.1.7)           | `>=8.5.10`    | Non-exploitable in admin runtime (CSS SSR only). Upgrade Next.js to 15.2+ in Phase 4. |
| `postcss`             | `8.4.31`          | High     | GHSA-qx2v-qp2m-jg93 (Subdependency of Next.js 15.1.7)           | `>=8.5.10`    | Non-exploitable in admin runtime. Upgrade Next.js in Phase 4.                         |
| `postcss`             | `8.4.31`          | Moderate | GHSA-fxqj-rqcc-2cmp (Subdependency of Next.js 15.1.7)           | `>=8.5.23`    | Dev build time only. Upgrade Next.js in Phase 4.                                      |
| `@opentelemetry/core` | `1.30.1`          | Moderate | GHSA-8988-4f7v-96qf (W3C Baggage propagation memory allocation) | `>=2.8.0`     | Non-exploitable (Baggage headers not exposed on unauthenticated ingress).             |
