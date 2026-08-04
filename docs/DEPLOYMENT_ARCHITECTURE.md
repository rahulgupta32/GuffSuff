# GuffSuff Deployment Architecture

> **Status**: Initial Draft (Phase 0 Bootstrap)

---

## Infrastructure Overview

- **Cloud / Container Hosting**: Docker containerized workloads managed via Terraform / Kubernetes.
- **Data Persistence**: Managed PostgreSQL 16 (Primary + Multi-AZ Read Replica) & Redis Cluster.
- **Network Isolation**: Private subnets for DB, Redis, and Worker instances. Public Load Balancer & WAF for API gateway.
