# GuffSuff Non-Functional Requirements (NFR)

> **Document Status**: Complete (Phase 1 Specification)

---

## 1. System Availability & Reliability

| Metric Target | Target Value | Status Tag | Rationale / Measurement Method |
| :--- | :--- | :--- | :--- |
| **API Availability** | 99.9% uptime | `proposed` | Calculated monthly excluding scheduled maintenance windows. |
| **Realtime WebSocket Uptime** | 99.95% connection availability | `proposed` | Measured via synthetic gateway connection probes every 30s. |
| **Recovery Point Objective (RPO)** | < 5 minutes | `approved` | PostgreSQL Write-Ahead Logging (WAL) streaming replication & backup. |
| **Recovery Time Objective (RTO)** | < 30 minutes | `approved` | Automated failover to standby database cluster. |

---

## 2. Latency & Performance Targets

| Operation | Target Latency | Status Tag | Benchmark Conditions |
| :--- | :--- | :--- | :--- |
| **API p95 Latency** | < 150ms | `pending benchmark` | Measured at API gateway under 1,000 req/sec load test. |
| **API p99 Latency** | < 350ms | `pending benchmark` | Standard database query optimization SLA. |
| **Online Message Delivery Latency** | < 200ms | `approved` | Time from sender socket send to recipient socket delivery notice. |
| **Push Notification Latency** | < 3.0s | `proposed` | FCM / APNs background delivery for online/idle mobile devices. |

---

## 3. Scale & Operational Boundaries

| Capacity / Parameter | Value / Limit | Status Tag | Rationale |
| :--- | :--- | :--- | :--- |
| **Max Group Members** | 256 members | `approved` | Prevents exponential fan-out payload performance degradation in E2EE MVP. |
| **Max Text Message Length** | 4,096 characters | `approved` | UTF-8 encoded text limits. |
| **Max Attachment File Size** | 50 MB | `pending business decision` | Applied to documents and videos. Voice notes capped at 10MB (approx 5 mins). |
| **Concurrent Active Devices per User**| 5 devices | `approved` | Maximum registered physical devices per account. |
| **OTP Expiration TTL** | 300 seconds (5 mins) | `approved` | Security window against brute force. |
| **OTP Resend Cooldown** | 60 seconds | `approved` | Rate limit protection against SMS provider cost floods. |
| **Message Edit Window** | 15 minutes | `proposed` | Allows correcting typos while maintaining conversation integrity. |
| **Delete for Everyone Window** | 60 minutes | `proposed` | Window after send for revoking sent messages. |
| **WebSocket Connection Capacity** | 10,000 sockets / pod | `pending benchmark` | Scaled horizontally behind Redis PubSub adapter. |

---

## 4. Mobile & Low-Bandwidth Constraints

- **Supported OS Versions**: Android 7.0+ (API 24), iOS 15.0+ (`approved`).
- **Memory Footprint**: App must operate cleanly on devices with 2GB RAM without triggering low-memory OS crashes (`approved`).
- **Low-Bandwidth Resilience**: Automatic compression of outbound payloads, offline local SQLite message queueing up to 10,000 pending messages, and exponential backoff retry jitter (`approved`).
