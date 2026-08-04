# GuffSuff System Architecture Specification

> **Status**: Initial Draft (Phase 0 Bootstrap)

---

## 1. Top-Level Monorepo Component Diagram

```text
+-----------------------------------------------------------------------+
|                            MOBILE CLIENTS                             |
|              Flutter (Android / iOS) + Drift Encrypted Local DB        |
+-----------------------------------+-----------------------------------+
                                    |
                    +---------------+---------------+
                    | HTTPS REST    | WebSockets    |
                    v               v               v
+-----------------------+   +-----------------------+
|      API SERVICE      |   |   REALTIME SERVICE    |
|   Authentication,     |   |  WebSocket Gateway,   |
|   Prekeys, Accounts,  |   |  Online Presence,     |
|   Media Auth          |   |  Envelope Delivery    |
+-----------+-----------+   +-----------+-----------+
            |                           |
            +-------------+-------------+
                          |
                          v
         +----------------------------------+
         |         PERSISTENCE LAYER        |
         |  PostgreSQL 16 (Durable Metadata)|
         |  Redis 7.2 (PubSub, RateLimits)  |
         |  S3-Compatible Object Store      |
         +----------------------------------+
```

---

## 2. Technology Stack Selection Criteria

- **Mobile Framework**: Flutter with Riverpod, GoRouter, Dio, and Drift (encrypted local storage).
- **Backend API**: TypeScript / NestJS (or Go after detailed evaluation in Phase 1).
- **Database**: PostgreSQL (Relational schema, strict foreign keys, index optimization, partitioning).
- **In-Memory Store**: Redis (Rate limiting, pub/sub realtime routing, session tokens).
- **Object Storage**: S3-compatible (Encrypted blobs, short-lived presigned URLs).
