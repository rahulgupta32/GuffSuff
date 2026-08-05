# GuffSuff Monorepo

> **Secure, Privacy-Focused, Nepal-First Messaging & Communication Platform**  
> Repository Owner: Rahul Gupta (`@rahulgupta32`)  
> Repository: `git@github.com:rahulgupta32/GuffSuff.git`

---

## 1. Prerequisites

- **Node.js**: `v24.15.0` (LTS)
- **pnpm**: `v11.20.0`
- **Docker Desktop / Engine**: Docker 26+ and Docker Compose v2+
- **Flutter SDK** _(Optional for mobile development)_: `v3.29.2` (Dart `3.7.0`)

---

## 2. Installation & Setup

```bash
# 1. Clone repository
git clone git@github.com:rahulgupta32/GuffSuff.git
cd GuffSuff

# 2. Copy environment file
cp .env.example .env

# 3. Install monorepo dependencies
pnpm install
```

---

## 3. Local Services & Docker Infrastructure

```bash
# Start PostgreSQL 16, Redis 7.2, MinIO, and OpenTelemetry Collector
make dev

# Check container health and logs
docker compose ps
make logs
```

---

## 4. Database Setup & Migration Execution

```bash
# Apply initial database migrations
pnpm --filter @guffsuff/database migrate

# Reset local development database (requires confirmation)
make db-reset-local
```

---

## 5. Starting Applications & Services

```bash
# Start all backend service applications in development mode
pnpm dev

# Or start individual services:
pnpm --filter @guffsuff/api dev       # API Service (Port 3000)
pnpm --filter @guffsuff/realtime dev  # Realtime Gateway (Port 3001)
pnpm --filter @guffsuff/worker dev    # Queue Worker
pnpm --filter @guffsuff/admin dev     # Admin Web Console (Port 3002)
```

---

## 6. Testing, Quality & Security Commands

```bash
# Run unit and integration tests
pnpm test
pnpm test:integration

# Type checking & linting
pnpm typecheck
pnpm lint

# Format checking & auto-formatting
pnpm format:check
pnpm format:write

# Security & Secret Scanning
pnpm security:scan
```

---

## 7. Repository Structure

```text
GuffSuff/
├── apps/
│   ├── admin/             # Next.js 15 Administrative Web Console
│   └── mobile/            # Flutter 3.29 Mobile Application (Android / iOS)
├── services/
│   ├── api/               # NestJS REST Gateway
│   ├── realtime/          # NestJS WebSocket Gateway
│   └── worker/            # NestJS BullMQ Queue Worker
├── packages/
│   ├── contracts/         # Zod schemas & transport contract types
│   ├── crypto-adapter/    # Zero-knowledge E2EE interface abstraction
│   ├── database/          # PostgreSQL Kysely / Prisma client & migrations
│   ├── design-system/     # Brand tokens & design components
│   ├── errors/            # Standardized domain error classes
│   ├── id-generation/     # UUIDv7 identifier generators
│   ├── localization/      # English & Nepali translation dictionaries
│   ├── logger/            # Allowlist-based Pino structured JSON logger
│   ├── observability/     # OpenTelemetry tracing & Prometheus metrics
│   ├── object-storage/    # MinIO / S3 object storage abstraction
│   ├── queue/             # BullMQ Redis queue connection factory
│   ├── shared-config/     # TypeScript, ESLint, & Prettier presets
│   └── test-utils/        # Fictional test data & mock fixtures
├── docs/                  # Architecture, ADRs, Threat Models, Runbooks
├── .github/workflows/     # 16 Least-privilege CI/CD workflows
└── docker-compose.yml     # Local environment stack definition
```

---

## 8. Troubleshooting

- **Redis connection rejected**: Ensure `guffsuff-redis` container is healthy (`docker compose ps`).
- **PostgreSQL authentication failed**: Verify `DATABASE_URL` in `.env` matches credentials in `docker-compose.yml`.
- **TypeScript workspace build error**: Run `pnpm build` from monorepo root to build shared packages before dependent services.
