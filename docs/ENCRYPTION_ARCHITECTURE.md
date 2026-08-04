# GuffSuff Encryption Architecture & Cryptographic Boundary

> **Document Status**: Complete (Phase 1 Specification)  
> **Crypto Abstraction Package**: `packages/crypto-adapter`  
> **Production Crypto Selection**: DEFERRED TO PHASE 2 APPROVAL DECISION

---

## 1. Crypto Abstraction Boundary (`packages/crypto-adapter`)

To strictly prevent custom cryptography implementations or tight coupling to a single crypto engine, all GuffSuff application code (Flutter app and NestJS backend) interacts exclusively with the `ICryptoAdapter` interface.

```typescript
export interface ICryptoAdapter {
  generateIdentityKeyPair(): Promise<IdentityKeyPair>;
  generatePrekeyBundle(count: number): Promise<PrekeyBundle>;
  establishOutboundSession(recipientPrekeyBundle: PrekeyBundle): Promise<SessionState>;
  encryptPayload(session: SessionState, plaintext: Uint8Array): Promise<EncryptedEnvelopePayload>;
  decryptPayload(session: SessionState, envelope: EncryptedEnvelopePayload): Promise<Uint8Array>;
  encryptAttachment(fileData: Uint8Array): Promise<{ ciphertext: Uint8Array; mediaKey: Uint8Array; iv: Uint8Array; mac: Uint8Array }>;
  decryptAttachment(ciphertext: Uint8Array, mediaKey: Uint8Array, iv: Uint8Array, mac: Uint8Array): Promise<Uint8Array>;
}
```

---

## 2. Mock vs Production Driver Policy

### `MockCryptoAdapter` (Development Phase 5 Only)
- Uses simple AES-256-GCM with fixed development keys for early UI and transport pipeline testing.
- **SECURITY GUARD**: Must display a visible yellow warning banner in app UI ("DEVELOPMENT MOCK ENCRYPTION ACTIVE") and MUST throw a hard build failure if `NODE_ENV=production` or `APP_ENV=production`.

### Production Encryption Candidate Evaluation (Phase 2 Review)
1. **Option A (Signal Protocol / `libsignal`)**: Proven asynchronous ratchet scheme, pairwise session ratcheting, forward secrecy, post-compromise security. Licensing and mobile binding audit required in Phase 2.
2. **Option B (Messaging Layer Security - MLS / RFC 9420)**: Efficient tree-based group key agreement for groups, reducing $O(N)$ pairwise message fan-out overhead.

---

## 3. Attachment & Group Encryption Rules

- **Attachment Encryption**: Sender generates unique random 256-bit key $K_{media}$ and 96-bit IV per file. Encrypts file locally via AES-256-GCM. Uploads ciphertext blob. $K_{media}$ is encrypted inside the pairwise E2EE message envelope.
- **Device Verification**: Safety numbers (fingerprints) derived from identity public keys allow users to visually or QR-scan verify session integrity. Key changes trigger explicit in-chat warnings.
