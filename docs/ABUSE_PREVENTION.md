# GuffSuff Abuse Prevention Architecture

> **Status**: Initial Draft (Phase 0 Bootstrap)

---

## Multilayered Anti-Abuse Strategy

1. **OTP Rate Limiting**: Cooldowns per phone number (+977), IP subnet, and ASN.
2. **Conversation & Message Limits**: Thresholds on new conversation initiation by unverified accounts.
3. **User Blocking & Escalation**: In-app one-tap user block and encrypted report payload submission.
4. **Zero-Content-Surveillance**: Abuse detection relies purely on behavioral signals, metadata rates, and explicit user reports without inspecting E2EE message text.
