# GuffSuff (गफगाफ / गफसफ)

> **Secure, Privacy-Focused, Nepal-First Messaging & Communication Platform**

[![CI Pipeline](https://github.com/rahulgupta32/GuffSuff/actions/workflows/ci.yml/badge.svg)](https://github.com/rahulgupta32/GuffSuff/actions/workflows/ci.yml)
[![Security Scan](https://github.com/rahulgupta32/GuffSuff/actions/workflows/security-scan.yml/badge.svg)](https://github.com/rahulgupta32/GuffSuff/actions/workflows/security-scan.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## ⚠️ Security Notice & Development Status

**NOTICE**: GuffSuff is currently in active pre-production bootstrap and architecture development. Early dev iterations may utilize non-production crypto adapters until audited end-to-end encryption libraries are integrated and approved. **Do not use in production or for real sensitive communications during development phases.**

---

## Product Overview

GuffSuff is an original, production-grade messaging platform designed specifically with a Nepal-first emphasis while adhering to international security, privacy, and performance standards.

### Key Capabilities (MVP Scope)
- **Phone-Number Registration & Verification**: Nepal phone-number format validation (+977 E.164 normalization) and OTP verification with progressive cooldowns.
- **Privacy-Preserving Contact Discovery**: Local phone normalization and zero-knowledge hashed lookup with rate limiting.
- **End-to-End Encrypted Messaging**: 1-to-1 and group text messaging, delivery/read states, reactions, reply/forward/edit/delete.
- **Encrypted Media Sharing**: Client-side AES-GCM encrypted media transfers (images, videos, audio, voice notes, documents, location preview).
- **Nepal-First User Experience**: Native Devanagari script support, Asia/Kathmandu timezone alignment, low-bandwidth data saver mode, and sub-$100 Android device optimization.
- **Trust & Safety / Admin Console**: Role-based administrative dashboard with zero plaintext access to user messages.

---

## Monorepo Architecture

```text
GuffSuff/
├── .github/              # GitHub Action workflows, issue templates, dependabot
├── apps/                 # Application frontends
│   ├── mobile/           # Flutter Android & iOS client
│   └── admin/            # Administrative & Trust & Safety web console
├── services/             # Backend microservices / core APIs
│   ├── api/              # HTTP API (Authentication, Account, Devices, Media metadata)
│   ├── realtime/         # WebSocket / Realtime delivery engine
│   └── worker/           # Background jobs & delayed push notifications
├── packages/             # Shared TypeScript / Dart monorepo modules
│   ├── contracts/        # Shared OpenAPI & schema definitions
│   ├── crypto-adapter/   # Cryptographic abstraction interface & drivers
│   ├── design-system/    # GuffSuff UI theme and component tokens
│   ├── localization/     # ARB & JSON translation assets (Nepali & English)
│   ├── shared-config/    # Shared lint, TypeScript, and environment validation
│   └── test-utils/       # Mock data generators and test helpers
├── infrastructure/       # Container & IaC manifests
│   ├── docker/           # Docker Compose local dev stack
│   ├── terraform/        # Cloud infrastructure definitions
│   ├── kubernetes/       # Production K8s manifests
│   └── monitoring/       # Prometheus & Grafana alerts/dashboards
├── docs/                 # Product requirements, architecture & security specs
│   ├── adr/              # Architecture Decision Records
│   ├── diagrams/         # System architecture & flow diagrams
│   └── runbooks/         # Incident response & operational runbooks
└── scripts/              # Local setup & administrative scripts
```

---

## Prerequisites

- **Flutter**: `>= 3.19.0` (with Dart `>= 3.3.0`)
- **Node.js**: `>= 20.11.0 LTS`
- **Docker & Docker Compose**: `>= 25.0`
- **PostgreSQL**: `>= 16.0` (or via Docker)
- **Redis**: `>= 7.2` (or via Docker)

---

## Quick Local Setup

1. **Clone the Repository**:
   ```bash
   git clone git@github.com:rahulgupta32/GuffSuff.git
   cd GuffSuff
   ```

2. **Environment Configuration**:
   ```bash
   cp .env.example .env
   ```

3. **Start Local Development Services**:
   ```bash
   docker compose -f infrastructure/docker/docker-compose.yml up -d
   ```

---

## Development & Test Commands

| Command | Action |
| :--- | :--- |
| `make dev` | Launch local API, Realtime service, Worker, and DB containers |
| `make test` | Run unit & integration test suites across all services & packages |
| `make lint` | Run pre-commit linter & static code analysis |
| `make build` | Compile backend services and validate Flutter build constraints |
| `make db-migrate` | Run database schema migrations |

---

## Documentation Index

- 📋 [Product Requirements Document](docs/PRODUCT_REQUIREMENTS.md)
- 🏗️ [System Architecture](docs/SYSTEM_ARCHITECTURE.md)
- 🗄️ [Data Model Specification](docs/DATA_MODEL.md)
- 🔌 [API Specification](docs/API_SPECIFICATION.md)
- ⚡ [Realtime Delivery Protocol](docs/REALTIME_PROTOCOL.md)
- 🔐 [Encryption Architecture](docs/ENCRYPTION_ARCHITECTURE.md)
- 🛡️ [STRIDE Threat Model](docs/THREAT_MODEL.md)
- 👁️ [Privacy Model](docs/PRIVACY_MODEL.md)
- 🛑 [Abuse Prevention Model](docs/ABUSE_PREVENTION.md)
- 🚀 [Deployment Architecture](docs/DEPLOYMENT_ARCHITECTURE.md)
- 📊 [Observability & Monitoring](docs/OBSERVABILITY.md)
- 🧪 [Test Strategy](docs/TEST_STRATEGY.md)
- 📦 [Release Checklist](docs/RELEASE_CHECKLIST.md)
- 📜 [Architecture Decision Log](docs/DECISION_LOG.md)
- 🗺️ [Product Roadmap](docs/ROADMAP.md)

---

## Vulnerability Reporting

Please review [`SECURITY.md`](SECURITY.md) for details on responsible vulnerability disclosure.

---

## License

This project is licensed under the terms of the MIT License. See [`LICENSE`](LICENSE) for details.
