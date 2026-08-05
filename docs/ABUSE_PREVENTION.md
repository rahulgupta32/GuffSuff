# GuffSuff Abuse Prevention & Trust Architecture

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Constraint**: Abuse controls MUST operate without server access to private message plaintext (`SEC-ABUSE-001`).

---

## 1. Rate Limiting & Behavioral Abuse Controls

| Action Category               | Applied Limit                     | Defense Mechanism                  | Mitigation Action                      |
| :---------------------------- | :-------------------------------- | :--------------------------------- | :------------------------------------- |
| **New Conversation Start**    | Max 10 new chats / hour           | Sliding window rate limit in Redis | Block new chat initiation for 1 hour.  |
| **Group Invite Dispatches**   | Max 5 group invites / hour        | Group creation rate limit          | Require CAPTCHA or delay invite links. |
| **Media File Uploads**        | 50MB per file / 500MB daily quota | Presigned URL quota check          | Reject presigned upload URL issuance.  |
| **Contact Discovery Queries** | Max 50 queries / hour             | Redis rate limiter                 | Return 429 Too Many Requests.          |

---

## 2. Recipient-Submitted Abuse Reports

- Users can submit user reports containing voluntarily attached decrypted evidence (last 5 messages in chat).
- Decrypted evidence is transmitted via separate encrypted report payload to Trust & Safety.
- Clear UI disclosures explain exactly what evidence is shared before user confirms submission.
- Analysts review reports in `apps/admin` under strict RBAC audit logging.
