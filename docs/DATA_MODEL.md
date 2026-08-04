# GuffSuff Data Model Specification

> **Status**: Initial Draft (Phase 0 Bootstrap)

---

## 1. Domain Entities & Storage Strategy

- **User**: System user record with UUIDv7 identifier.
- **PhoneIdentity**: E.164 normalized phone number (+977...), stored in encrypted/restricted columns.
- **UserProfile**: Display name, avatar media URL, bio, privacy settings.
- **Device**: Registered user hardware device with device identity keys.
- **DeviceKeyBundle**: Public identity keys, signed prekeys, and one-time prekeys for E2EE session setup.
- **Conversation**: Direct (1:1) or Group chat metadata.
- **MessageEnvelope**: Server-side opaque encrypted message container (no plaintext).
- **Attachment**: Opaque encrypted media blob reference with short-lived presigned download links.
