# GuffSuff Observability & Security Monitoring Policy

> **Document Status**: Phase 2 Security Architecture Baseline

---

## 1. Security Telemetry & Metrics

- Metrics exported via Prometheus endpoints on private internal ports (`/metrics`).
- High-priority security alerts:
  - Excessive OTP requests or verification failures (> 10/min).
  - Rapid rate-limit threshold trips (HTTP 429 surges).
  - Database connection pool exhaustion or query latency spikes (> 500ms).
  - Unhandled WebSocket authentication failures.
