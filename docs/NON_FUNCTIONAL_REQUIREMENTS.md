# GuffSuff Non-Functional Requirements (NFR)

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Warning**: GuffSuff does not yet contain production end-to-end encryption and must not be marketed or represented as cryptographically secure until implementation, independent review, and release acceptance gates are completed.

---

## 1. Decision Status Vocabulary

All architectural, non-functional, and product parameters use the following standardized decision-status vocabulary:

- **Proposed**: Initial architectural recommendation submitted for review.
- **Under evaluation**: Active technical prototyping or security analysis underway.
- **Approved by product owner**: Explicitly accepted by `@rahulgupta32` with recorded date and evidence.
- **Approved by security review**: Accepted by Lead Security Reviewer following formal review.
- **Pending benchmark**: Awaiting performance, load, or latency testing under realistic conditions.
- **Rejected**: Explicitly evaluated and declined.
- **Superseded**: Replaced by a newer decision record.

> **RULE**: The status `Approved` MUST NOT be used without explicitly specifying the approver, decision date, supporting evidence, and associated ADR or decision-log entry.

---

## 2. System Availability & Reliability

| Metric Target                      | Target Value                   | Decision Status | Rationale / Measurement Method                                       |
| :--------------------------------- | :----------------------------- | :-------------- | :------------------------------------------------------------------- |
| **API Availability**               | 99.9% uptime                   | `Proposed`      | Calculated monthly excluding scheduled maintenance windows.          |
| **Realtime WebSocket Uptime**      | 99.95% connection availability | `Proposed`      | Measured via synthetic gateway connection probes every 30s.          |
| **Recovery Point Objective (RPO)** | < 5 minutes                    | `Proposed`      | PostgreSQL Write-Ahead Logging (WAL) streaming replication & backup. |
| **Recovery Time Objective (RTO)**  | < 30 minutes                   | `Proposed`      | Automated failover to standby database cluster.                      |

---

## 3. Latency & Performance Targets

| Operation                           | Target Latency | Decision Status     | Benchmark Conditions                                              |
| :---------------------------------- | :------------- | :------------------ | :---------------------------------------------------------------- |
| **API p95 Latency**                 | < 150ms        | `Pending benchmark` | Measured at API gateway under 1,000 req/sec load test.            |
| **API p99 Latency**                 | < 350ms        | `Pending benchmark` | Standard database query optimization SLA.                         |
| **Online Message Delivery Latency** | < 200ms        | `Proposed`          | Time from sender socket send to recipient socket delivery notice. |
| **Push Notification Latency**       | < 3.0s         | `Proposed`          | FCM / APNs background delivery for online/idle mobile devices.    |

---

## 4. Scale & Operational Boundaries

| Capacity / Parameter                   | Value / Limit        | Decision Status     | Rationale                                                                    |
| :------------------------------------- | :------------------- | :------------------ | :--------------------------------------------------------------------------- |
| **Max Group Members**                  | 256 members          | `Proposed`          | Prevents exponential fan-out payload performance degradation in E2EE MVP.    |
| **Max Text Message Length**            | 4,096 characters     | `Proposed`          | UTF-8 encoded text limits.                                                   |
| **Max Attachment File Size**           | 50 MB                | `Proposed`          | Applied to documents and videos. Voice notes capped at 10MB (approx 5 mins). |
| **Concurrent Active Devices per User** | 5 devices            | `Proposed`          | Maximum registered physical devices per account.                             |
| **OTP Expiration TTL**                 | 300 seconds (5 mins) | `Proposed`          | Security window against brute force.                                         |
| **OTP Resend Cooldown**                | 60 seconds           | `Proposed`          | Rate limit protection against SMS provider cost floods.                      |
| **Message Edit Window**                | 15 minutes           | `Proposed`          | Allows correcting typos while maintaining conversation integrity.            |
| **Delete for Everyone Window**         | 60 minutes           | `Proposed`          | Window after send for revoking sent messages.                                |
| **WebSocket Connection Capacity**      | 10,000 sockets / pod | `Pending benchmark` | Scaled horizontally behind Redis PubSub adapter.                             |

---

## 5. Mobile & Low-Bandwidth Constraints

- **Supported OS Versions**: Android 7.0+ (API 24), iOS 15.0+ (`Proposed`).
- **Memory Footprint**: App must operate cleanly on devices with 2GB RAM without triggering low-memory OS crashes (`Proposed`).
- **Low-Bandwidth Resilience**: Automatic compression of outbound payloads, offline local SQLite message queueing up to 10,000 pending messages, and exponential backoff retry jitter (`Proposed`).
