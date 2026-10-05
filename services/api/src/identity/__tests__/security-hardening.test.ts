import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { PhoneNumberService } from "../phone-number.service.js";

describe("Phase 4 Security Hardening & Concurrency Tests", () => {
  describe("AES-256-GCM Nonce & Envelope Hardening", () => {
    test("Generates 1000 unique 12-byte nonces across consecutive encryptions", () => {
      const phoneService = new PhoneNumberService();
      const nonces = new Set<string>();
      const sampleCount = 1000;
      const phone = "+9779841234567";

      for (let i = 0; i < sampleCount; i++) {
        const encrypted = phoneService.encryptPhoneNumber(phone);
        const ivHex = encrypted.subarray(0, 12).toString("hex");
        assert.equal(ivHex.length, 24, "IV must be 12 bytes (24 hex chars)");
        nonces.add(ivHex);
      }

      assert.equal(nonces.size, sampleCount, "All 1000 IV nonces must be completely unique");
    });

    test("Fails closed on tampered ciphertext", () => {
      const phoneService = new PhoneNumberService();
      const encrypted = phoneService.encryptPhoneNumber("+9779841234567");
      // Tamper ciphertext byte
      const tampered = Buffer.from(encrypted);
      const lastIndex = tampered.length - 1;
      tampered[lastIndex] = (tampered[lastIndex] ?? 0) ^ 0xff;

      assert.throws(() => {
        phoneService.decryptPhoneNumber(tampered);
      }, /Unsupported state|unable to authenticate|decryption failed/i);
    });

    test("Fails closed on tampered authentication tag", () => {
      const phoneService = new PhoneNumberService();
      const encrypted = phoneService.encryptPhoneNumber("+9779841234567");
      // Tamper tag byte (bytes 12-27)
      const tampered = Buffer.from(encrypted);
      tampered[15] = (tampered[15] ?? 0) ^ 0xff;

      assert.throws(() => {
        phoneService.decryptPhoneNumber(tampered);
      }, /Unsupported state|unable to authenticate|decryption failed/i);
    });

    test("Fails closed on invalid Buffer length", () => {
      const phoneService = new PhoneNumberService();
      const invalidBuffer = Buffer.from("short");

      assert.throws(() => {
        phoneService.decryptPhoneNumber(invalidBuffer);
      });
    });
  });
});
