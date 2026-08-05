# Protocol Versioning & Upgrade Strategy

> **Document Status**: Migration & Fail-Closed Protocol Upgrade Policy

---

## 1. Version Identifiers

- **Protocol Version 1**: Phase 5 Opaque Encrypted Envelope Transport Baseline (Test mode / unencrypted placeholder payloads).
- **Protocol Version 2**: Phase 6 Signal Protocol / E2EE Encrypted Envelopes.

---

## 2. Upgrade Rules & Downgrade Prevention

1. **Fail-Closed Policy**: Clients MUST reject any incoming envelope with `protocolVersion < 2` once E2EE capability has been negotiated for a conversation.
2. **Server Enforcement**: API rejects envelope submissions with unrecognized or deprecated `protocolVersion` numbers.
3. **Rollback Prohibition**: Once a device pair establishes a Version 2 session, fallback to Version 1 is strictly forbidden to prevent protocol downgrade attacks.
