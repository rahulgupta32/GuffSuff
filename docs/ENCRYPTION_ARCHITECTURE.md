# GuffSuff Encryption Architecture & Cryptographic Boundary

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Crypto Abstraction Package**: `packages/crypto-adapter`  
> **Warning**: GuffSuff does not yet contain production end-to-end encryption and must not be marketed or represented as cryptographically secure until implementation, independent review, and release acceptance gates are completed.

---

## 1. Cryptographic Isolation Policy

To strictly prevent custom cryptography implementations or tight coupling to a single crypto engine, all GuffSuff application code interacts exclusively with the `ICryptoAdapter` interface in `packages/crypto-adapter`.

```typescript
export interface ICryptoAdapter {
  generateIdentityKeyPair(): Promise<IdentityKeyPair>;
  generatePrekeyBundle(count: number): Promise<PrekeyBundle>;
  establishOutboundSession(recipientPrekeyBundle: PrekeyBundle): Promise<SessionState>;
  encryptPayload(session: SessionState, plaintext: Uint8Array): Promise<EncryptedEnvelopePayload>;
  decryptPayload(session: SessionState, envelope: EncryptedEnvelopePayload): Promise<Uint8Array>;
  encryptAttachment(
    fileData: Uint8Array
  ): Promise<{ ciphertext: Uint8Array; mediaKey: Uint8Array; iv: Uint8Array; mac: Uint8Array }>;
  decryptAttachment(
    ciphertext: Uint8Array,
    mediaKey: Uint8Array,
    iv: Uint8Array,
    mac: Uint8Array
  ): Promise<Uint8Array>;
}
```

---

## 2. Production Crypto Provider Status: UNDER EVALUATION

- **Production Provider Selection**: **UNSELECTED / UNDER EVALUATION**. Signal Protocol (`libsignal`) and Messaging Layer Security (MLS / RFC 9420) are under evaluation during Phase 2.
- **No Production Crypto Implemented**: No production cryptographic algorithms, primitives, or Double Ratchet implementations exist in the repository currently.

---

## 3. Mock Provider Safeguards

If a future development mock is created for offline pipeline testing, it MUST enforce:

- Mandatory exclusion from production compilation.
- Startup failure if `NODE_ENV=production` or `APP_ENV=production`.
- Visible UI indicator on mobile app ("DEVELOPMENT MOCK ENCRYPTION ACTIVE").
- CI rejection rules blocking release builds containing mock symbols.
