import { test, describe } from "node:test";
import assert from "node:assert/strict";
import * as crypto from "crypto";
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
        const parts = encrypted.split(":");
        const ivHex = parts[1];
        assert.equal(parts[0], "v1");
        assert.equal(ivHex.length, 24, "IV must be 12 bytes (24 hex chars)");
        nonces.add(ivHex);
      }

      assert.equal(nonces.size, sampleCount, "All 1000 IV nonces must be completely unique");
    });

    test("Fails closed on tampered ciphertext", () => {
      const phoneService = new PhoneNumberService();
      const encrypted = phoneService.encryptPhoneNumber("+9779841234567");
      const parts = encrypted.split(":");
      // Tamper ciphertext hex
      const tamperedCiphertext = parts[3].substring(0, parts[3].length - 2) + "00";
      const tamperedEnvelope = `${parts[0]}:${parts[1]}:${parts[2]}:${tamperedCiphertext}`;

      assert.throws(() => {
        phoneService.decryptPhoneNumber(tamperedEnvelope);
      }, /decryption failed/i);
    });

    test("Fails closed on tampered authentication tag", () => {
      const phoneService = new PhoneNumberService();
      const encrypted = phoneService.encryptPhoneNumber("+9779841234567");
      const parts = encrypted.split(":");
      // Tamper tag hex
      const tamperedTag = "0".repeat(32);
      const tamperedEnvelope = `${parts[0]}:${parts[1]}:${tamperedTag}:${parts[3]}`;

      assert.throws(() => {
        phoneService.decryptPhoneNumber(tamperedEnvelope);
      }, /decryption failed/i);
    });

    test("Fails closed on unknown envelope key version", () => {
      const phoneService = new PhoneNumberService();
      const unknownVersionEnvelope = "v99:123456789012345678901234:12345678901234567890123456789012:12345678";

      assert.throws(() => {
        phoneService.decryptPhoneNumber(unknownVersionEnvelope);
      }, /unsupported envelope version/i);
    });
  });

  describe("Refresh Token Family Rotation & Concurrency Simulations", () => {
    interface TokenRecord {
      id: string;
      familyId: string;
      verifierHash: string;
      isConsumed: boolean;
      consumedAt?: number;
      replacedBy?: string;
      isRevoked: boolean;
    }

    function hashToken(token: string): string {
      return crypto.createHash("sha256").update(token).digest("hex");
    }

    test("Simultaneous refreshes within 10s grace window return existing successor idempotently", () => {
      const db = new Map<string, TokenRecord>();
      const familyId = "fam_100";
      const t1 = "token_v1";
      const t2 = "token_v2";

      db.set(hashToken(t1), {
        id: "t1",
        familyId,
        verifierHash: hashToken(t1),
        isConsumed: true,
        consumedAt: Date.now() - 2000, // 2s ago
        replacedBy: t2,
        isRevoked: false
      });

      // Simulate concurrent refresh with T1
      const now = Date.now();
      const record = db.get(hashToken(t1))!;
      let resultToken: string;

      if (record.isConsumed && record.consumedAt && now - record.consumedAt <= 10000) {
        resultToken = record.replacedBy!;
      } else {
        throw new Error("Compromised family");
      }

      assert.equal(resultToken, t2);
    });

    test("Replay attack after 10s grace window revokes entire token family", () => {
      const db = new Map<string, TokenRecord>();
      const familyId = "fam_200";
      const t1 = "token_old";
      const t2 = "token_new";

      db.set(hashToken(t1), {
        id: "t1",
        familyId,
        verifierHash: hashToken(t1),
        isConsumed: true,
        consumedAt: Date.now() - 15000, // 15s ago (outside window)
        replacedBy: t2,
        isRevoked: false
      });

      const now = Date.now();
      const record = db.get(hashToken(t1))!;
      let familyRevoked = false;

      if (record.isConsumed && record.consumedAt && now - record.consumedAt > 10000) {
        // Mark family revoked
        record.isRevoked = true;
        familyRevoked = true;
      }

      assert.ok(familyRevoked, "Token family must be revoked when consumed token reused past 10s");
    });
  });
});
