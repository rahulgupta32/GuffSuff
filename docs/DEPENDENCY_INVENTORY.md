# GuffSuff Dependency Inventory

> **Document Status**: Phase 3 Development Platform Baseline

---

## Workspace Dependency Inventory

| Package / Service          | Dependency Name      | Version   | Purpose                           | Approved License |
| :------------------------- | :------------------- | :-------- | :-------------------------------- | :--------------- |
| `guffsuff-monorepo`        | `turbo`              | `2.4.2`   | Monorepo build orchestrator       | MIT              |
| `guffsuff-monorepo`        | `typescript`         | `5.7.3`   | TypeScript compiler               | Apache-2.0       |
| `@guffsuff/contracts`      | `zod`                | `3.24.2`  | Schema validation                 | MIT              |
| `@guffsuff/logger`         | `pino`               | `9.6.0`   | Structured JSON logger            | MIT              |
| `@guffsuff/observability`  | `@opentelemetry/api` | `1.9.0`   | OpenTelemetry tracing API         | Apache-2.0       |
| `@guffsuff/database`       | `pg`                 | `8.13.1`  | PostgreSQL client                 | MIT              |
| `@guffsuff/queue`          | `bullmq`             | `5.41.6`  | Redis queue manager               | MIT              |
| `@guffsuff/object-storage` | `@aws-sdk/client-s3` | `3.750.0` | S3 API client                     | Apache-2.0       |
| `@guffsuff/api`            | `@nestjs/core`       | `11.0.1`  | NestJS REST framework             | MIT              |
| `@guffsuff/realtime`       | `socket.io`          | `4.8.1`   | Realtime WebSocket server         | MIT              |
| `@guffsuff/admin`          | `next`               | `15.1.7`  | Next.js web application framework | MIT              |
