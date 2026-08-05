# GuffSuff Master Data Retention Schedule & Policy

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Status**: Retention parameters marked `Under evaluation` pending final legal and multi-device review.

---

## 1. Master Retention Matrix

| Data / Artifact Category           | Proposed Retention Period     | Legal / Operational Justification | Deletion Mechanism              | Backup Effect                       | Legal Review Status | User-Facing Disclosure      | Approval Status    |
| :--------------------------------- | :---------------------------- | :-------------------------------- | :------------------------------ | :---------------------------------- | :------------------ | :-------------------------- | :----------------- |
| **OTP Request Log**                | 24 Hours                      | Rate limiting & abuse prevention  | Automated Redis key expiration  | Purged from Redis memory            | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **OTP Verification Event**         | 7 Days                        | Authentication audit trail        | Background worker DB purge      | Excluded from long-term DB backups  | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Failed OTP Attempt Count**       | 5 Minutes                     | Brute-force throttling            | Redis TTL expiration            | Ephemeral memory only               | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Active Access Session**          | 15 Minutes                    | Stateless API authentication      | JWT expiration                  | Not stored in DB                    | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Revoked Session Token**          | 30 Days                       | Prevents token reuse attacks      | Worker DB purge job             | Retained in rolling 30-day backups  | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **IP Address Logs**                | 14 Days                       | Infrastructure DDoS & WAF defense | CloudWatch / log drain purge    | Excluded from long-term storage     | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Device Registration History**    | Account lifetime              | Device security & unlinking UI    | Cascade purge on account delete | Purged within 30d of account delete | Pending             | Visible in App Settings     | `Proposed`         |
| **Security Event Logs**            | 90 Days                       | Intrusion detection & forensics   | Partition dropping              | Purged after 90 days                | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Undelivered Encrypted Envelope** | 30 Days                       | Asynchronous delivery queue       | Worker DB purge job             | Envelope purged from DB & backups   | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Delivered Encrypted Envelope**   | **7 Days (Under Evaluation)** | Server storage minimization       | Automated DB row deletion       | Purged from server DB               | Pending             | Disclosed in Privacy Policy | `Under evaluation` |
| **Read Receipts**                  | 7 Days                        | Receipt sync across devices       | Worker DB purge job             | Ephemeral DB state                  | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Ephemeral Presence**             | Real-time (TTL 60s)           | Live socket online status         | Redis key expiration            | Ephemeral memory only               | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Typing Indicators**              | Ephemeral (TTL 5s)            | Socket UI indicator               | Not persisted in DB             | Memory only                         | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Encrypted Media Attachment**     | 30 Days                       | Storage cost optimization         | Automated S3 Lifecycle rule     | Hard delete from S3 bucket          | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Orphaned Media Upload**          | 24 Hours                      | Cleans unlinked uploads           | S3 Lifecycle rule               | Hard delete from S3 bucket          | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **User Abuse Reports**             | 90 Days                       | Trust & Safety investigation      | Automated DB row purge          | Purged after 90 days                | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Report Decrypted Evidence**      | 30 Days after resolution      | T&S decision audit                | Hard DB row purge               | Purged after 30 days                | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Admin Audit Events**             | 7 Years                       | Regulatory audit & compliance     | Immutable append-only table     | Permanent archive backup            | Pending             | Disclosed in Privacy Policy | `Proposed`         |
| **Account Export Zip**             | 48 Hours                      | Prevents stale export storage     | Automated S3 Lifecycle rule     | Deleted from S3                     | Pending             | Visible in Export UI        | `Proposed`         |
| **Account Deletion Request**       | 30 Days                       | Soft-delete grace period          | Worker permanent purge job      | All user DB rows deleted within 30d | Pending             | Visible in Delete UI        | `Proposed`         |

---

## 2. Multi-Device History Sync & 7-Day Purge Re-Evaluation

The proposed **7-day delivered envelope purge** policy is explicitly marked `Under evaluation` because:

- If a secondary linked device stays offline longer than 7 days, or a new secondary device is linked, server-purged envelopes cannot be delivered from server storage.
- History synchronization MUST be executed device-to-device (P2P encrypted sync) or via encrypted client backup archives.
- The 7-day policy MUST NOT be approved until the multi-device history sync model is finalized in Phase 6.
