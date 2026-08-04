# GuffSuff Observability & Monitoring Specification

> **Status**: Initial Draft (Phase 0 Bootstrap)

---

## Telemetry Standards

- **Structured Logging**: JSON format with trace ID and request correlation headers.
- **Redaction Rules**: Automatic scrubbing of phone numbers, tokens, OTP codes, authorization headers, and ciphertexts.
- **Metrics**: Prometheus-compatible endpoints (`/metrics`) tracking latency (p95, p99), WebSocket connection counts, delivery success rate, and queue backlogs.
