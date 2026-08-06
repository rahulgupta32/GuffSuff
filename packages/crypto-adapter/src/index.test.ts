import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  CryptoAdapterError,
  ProviderUnavailableError,
  assertProductionProviderSafety,
  ProviderCapabilityMap,
} from "./index.js";

describe("CryptoAdapter Boundary Safety Test", () => {
  it("throws ProviderUnavailableError with default message", () => {
    const err = new ProviderUnavailableError();
    assert.ok(err.message.includes("SECURE MESSAGING PROVIDER UNAVAILABLE"));
    assert.strictEqual(err.code, "KEY_STORAGE_UNAVAILABLE");
  });

  it("permits production load of a non-test provider", () => {
    const caps: ProviderCapabilityMap = {
      supportsDirectMessaging: true,
      supportsGroupMessaging: true,
      supportedProtocolVersions: [1],
      providerId: "production-native-provider",
      providerVersion: "1.0.0",
      isTestProvider: false,
    };
    assert.doesNotThrow(() => assertProductionProviderSafety(caps, true));
  });

  it("prohibits production load of a test provider", () => {
    const caps: ProviderCapabilityMap = {
      supportsDirectMessaging: true,
      supportsGroupMessaging: false,
      supportedProtocolVersions: [1],
      providerId: "test-boundary-provider",
      providerVersion: "0.1.0",
      isTestProvider: true,
    };
    assert.throws(
      () => assertProductionProviderSafety(caps, true),
      (err: unknown) => {
        return err instanceof CryptoAdapterError && err.message.includes("PROHIBITED: Test provider");
      }
    );
  });
});
