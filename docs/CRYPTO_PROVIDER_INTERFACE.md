# Cryptographic Provider Interface & Capabilities Architecture

> **Document Status**: Official Interface & Capabilities Specification (Phase 6A)

---

## 1. Provider Capability Negotiation

Providers query capabilities dynamically via `queryCapabilities()` returning a `ProviderCapabilityMap`:

- `supportsDirectMessaging`: Boolean (Track A capability)
- `supportsGroupMessaging`: Boolean (Track B capability)
- `supportedProtocolVersions`: Array of supported protocol versions (e.g. `[1]`)
- `providerId`: Human-readable identifier
- `providerVersion`: Version string
- `isTestProvider`: Flag indicating non-production test status

---

## 2. Error Model & Production Fallback

```typescript
export class ProviderUnavailableError extends CryptoAdapterError {
  constructor(message: string = "SECURE MESSAGING PROVIDER UNAVAILABLE") {
    super("KEY_STORAGE_UNAVAILABLE", message);
  }
}
```

When no secure provider is available or capability negotiation fails, application operations reject with `SECURE MESSAGING PROVIDER UNAVAILABLE`.
