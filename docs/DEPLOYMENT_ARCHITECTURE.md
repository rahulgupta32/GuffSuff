# GuffSuff Deployment Architecture & Cloud Evaluation

> **Document Status**: Complete (Phase 1 Specification)  
> **Deployment Model**: Cloud-Neutral Containerized Infrastructure (Docker / Kubernetes / Terraform)

---

## 1. Network Topology & Trust Boundaries

```text
                                [ PUBLIC INTERNET ]
                                         |
                                         v
                         +-------------------------------+
                         |   WAF & PUBLIC LOAD BALANCER  |
                         +---------------+---------------+
                                         |
                     +-------------------+-------------------+
                     | Public Subnet                         |
                     v                                       v
         +-----------------------+               +-----------------------+
         |    services/api       |               |   services/realtime   |
         |   (REST API Pods)     |               | (WebSocket Gateway)   |
         +-----------+-----------+               +-----------+-----------+
                     |                                       |
                     +-------------------+-------------------+
                                         | Private Subnet
                     +-------------------+-------------------+
                     |                                       |
                     v                                       v
         +-----------------------+               +-----------------------+
         |    services/worker    |               |    Redis Cluster      |
         |   (Background Queue)  |               | (Rate Limits, PubSub) |
         +-----------+-----------+               +-----------------------+
                     |
                     v
         +-----------------------+               +-----------------------+
         |     PostgreSQL 16     |               | S3 Encrypted Storage  |
         | (Primary + Read Repl) |               |  (Opaque Media Blobs) |
         +-----------------------+               +-----------------------+
```

---

## 2. High-Level Cloud Provider Comparison

| Evaluation Metric                   | AWS (Amazon Web Services)       | GCP (Google Cloud Platform)           | Azure (Microsoft)               |
| :---------------------------------- | :------------------------------ | :------------------------------------ | :------------------------------ |
| **Nearest Region Latency to Nepal** | `ap-south-1` (Mumbai: ~35-45ms) | `asia-south1` (Mumbai: ~35-45ms)      | `centralindia` (Pune: ~40-50ms) |
| **Managed DB Service**              | AWS RDS PostgreSQL              | GCP Cloud SQL for PostgreSQL          | Azure Database for PostgreSQL   |
| **Kubernetes Engine**               | AWS EKS                         | GCP GKE (Best-in-class control plane) | Azure AKS                       |
| **S3 Storage Engine**               | AWS S3                          | GCP Cloud Storage                     | Azure Blob Storage              |
| **Startup Credits / Cost**          | High eligibility                | High eligibility                      | Medium                          |

> **RECOMMENDATION**: AWS (`ap-south-1`) or GCP (`asia-south1`) for lowest network latency to Nepal telecom backbones. **Final Cloud Provider selection is PENDING APPROVAL.**
