# ADR-036: Privacy-Safe Observability Foundation

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: DevSecOps Lead, Security Lead
- **Decision Status**: Proposed

## Context

GuffSuff requires distributed tracing, correlation IDs, and metrics across microservices without emitting sensitive user data or credentials to telemetry streams.

## Decision

Implement OpenTelemetry SDK with W3C `traceparent` propagation and Pino allowlist structured JSON logging. Prometheus metrics endpoints are bound strictly to internal network ports.
