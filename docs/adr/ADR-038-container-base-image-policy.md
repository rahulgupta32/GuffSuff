# ADR-038: Multi-Stage Non-Root Container Base-Image Policy

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: DevSecOps Lead
- **Decision Status**: Proposed

## Context

Container images built with root privileges or bloated base images increase container breakout risks and CVE vulnerability surfaces.

## Decision

Production Dockerfiles MUST use multi-stage builds over minimal Alpine/Distroless base images (`node:24.15.0-alpine3.21`) pinned to exact version tags. Containers execute under unprivileged non-root users (`node`).
