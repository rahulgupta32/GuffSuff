# ADR-006: S3-Compatible Encrypted Object Storage

- **Status**: Approved
- **Date**: 2026-08-05
- **Deciders**: Rahul Gupta (`@rahulgupta32`), GuffSuff Lead Architecture Team

---

## Context

GuffSuff supports encrypted media sharing (images, videos, audio notes, voice messages, documents). Plaintext files must never reside on cloud infrastructure. Storage infrastructure must support cloud independence (AWS S3, MinIO, GCP Cloud Storage).

---

## Decision

We select **S3-Compatible Object Storage** with client-side encrypted blobs and short-lived presigned URLs.

### Operational Model
1. Sender client encrypts attachment locally using random key $K_{media}$ via AES-256-GCM.
2. Sender requests single-use presigned upload URL from `services/api`.
3. Sender uploads opaque ciphertext binary blob directly to Object Storage.
4. Recipient downloads ciphertext blob using short-lived presigned URL (max 15-minute validity).
5. Recipient decrypts blob locally using $K_{media}$ passed via E2EE message envelope.

---

## Security Controls
- Object storage buckets MUST be strictly private with public access blocked.
- Server never holds unencrypted media or decryption keys.
- EXIF metadata (GPS coordinates, camera metadata) stripped client-side prior to encryption.

---

## Alternatives Considered
- Direct server file proxying: Rejected due to server CPU/memory exhaustion and bandwidth bottleneck.
