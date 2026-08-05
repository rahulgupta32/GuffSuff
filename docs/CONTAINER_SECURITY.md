# GuffSuff Container Security Policy

> **Document Status**: Phase 3 Development Platform Baseline

---

## 1. Base Image & Execution Rules

- **Minimal Base Images**: Production Dockerfiles MUST use `node:24.15.0-alpine3.21` pinned to exact minor and OS patch versions. Floating tags (`latest`) are strictly forbidden (`ADR-038`).
- **Non-Root Execution**: Containers execute under unprivileged user `USER node`.
- **Multi-Stage Compilation**: Source code and build tools are discarded in builder stages. Final runtime images contain minimal compiled assets only.
- **Vulnerability Remediation**: Images are scanned via Trivy (`container-scan.yml`). Builds fail if Critical or High vulnerabilities are detected.
