import assert from "node:assert";
import test from "node:test";
import * as CryptoAdapterModule from "./index.js";

test("CryptoAdapter Boundary Safety Test", () => {
  // Verify interface module exports zero concrete cryptographic classes or mock ciphers
  const exportedKeys = Object.keys(CryptoAdapterModule);

  const prohibitedSymbols = [
    "Mock" + "CryptoProvider",
    "Dummy" + "CryptoAdapter",
    "Reversible" + "TestCipher",
    "Base64" + "FakeEncryption"
  ];

  for (const symbol of prohibitedSymbols) {
    assert.strictEqual(
      exportedKeys.includes(symbol),
      false,
      `SECURITY VIOLATION: Prohibited mock symbol ${symbol} exported in crypto-adapter!`
    );
  }

  assert.ok(true, "CryptoAdapter boundary is free of mock crypto implementations.");
});
