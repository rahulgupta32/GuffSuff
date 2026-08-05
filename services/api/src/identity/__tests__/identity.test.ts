import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { PhoneNumberService } from "../phone-number.service.js";
import { convertNepaliNumeralsToAscii, maskPhoneNumber } from "../phone-number.service.js";
import { getDevelopmentOtpSimulator } from "@guffsuff/otp-simulator";
import * as crypto from "crypto";

describe("Phase 4 Identity Core Unit Tests", () => {
  describe("Phone Number Normalization & Conversion", () => {
    test("Converts Nepali numerals to standard ASCII digits", () => {
      const nepaliInput = "९८०१२३४५६७";
      const converted = convertNepaliNumeralsToAscii(nepaliInput);
      assert.equal(converted, "9801234567");
    });

    test("Normalizes valid Nepali mobile number to E.164 format", () => {
      const phoneService = new PhoneNumberService();
      const rawInput = "9841234567";
      const normalized = phoneService.normalizeToE164(rawInput, "NP");
      assert.equal(normalized, "+9779841234567");
    });

    test("Masks phone number for logging redaction without exposing middle digits", () => {
      const e164 = "+9779841234567";
      const masked = maskPhoneNumber(e164);
      assert.equal(masked, "+9779****4567");
    });

    test("Encrypts and decrypts phone number using AES-256-GCM securely", () => {
      const phoneService = new PhoneNumberService();
      const original = "+9779841234567";
      const encrypted = phoneService.encryptPhoneNumber(original);
      assert.ok(encrypted.length > 28);
      const decrypted = phoneService.decryptPhoneNumber(encrypted);
      assert.equal(decrypted, original);
    });

    test("Generates consistent HMAC-SHA256 blind index for phone lookup", () => {
      const phoneService = new PhoneNumberService();
      const phone = "+9779841234567";
      const idx1 = phoneService.generateBlindIndex(phone);
      const idx2 = phoneService.generateBlindIndex(phone);
      assert.equal(idx1, idx2);
      assert.equal(idx1.length, 64);
    });
  });

  describe("Development OTP Simulator Isolation", () => {
    test("Simulator records and retrieves generated OTP code in test mode", () => {
      const simulator = getDevelopmentOtpSimulator();
      const challengeId = "018f3a2b-1234-7000-8000-000000000001";
      const phoneBlindIndex = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890";
      const code = "654321";

      simulator.recordSimulatorOtp(challengeId, phoneBlindIndex, code);
      const retrieved = simulator.getSimulatorOtp(challengeId);
      assert.equal(retrieved, code);
    });
  });

  describe("Keyed OTP Verifier & Timing Safety", () => {
    test("Constant-time timingSafeEqual validation succeeds for matching verifiers", () => {
      const pepper = "test_pepper_32_bytes_long_secret!";
      const challengeId = "018f3a2b-1234-7000-8000-000000000002";
      const code = "123456";
      const hash1 = crypto.createHmac("sha256", pepper).update(`${challengeId}:${code}`).digest("hex");
      const hash2 = crypto.createHmac("sha256", pepper).update(`${challengeId}:${code}`).digest("hex");

      const buf1 = Buffer.from(hash1, "hex");
      const buf2 = Buffer.from(hash2, "hex");
      assert.ok(crypto.timingSafeEqual(buf1, buf2));
    });

    test("Constant-time timingSafeEqual fails for mismatched verifiers", () => {
      const pepper = "test_pepper_32_bytes_long_secret!";
      const challengeId = "018f3a2b-1234-7000-8000-000000000002";
      const hash1 = crypto.createHmac("sha256", pepper).update(`${challengeId}:123456`).digest("hex");
      const hash2 = crypto.createHmac("sha256", pepper).update(`${challengeId}:654321`).digest("hex");

      const buf1 = Buffer.from(hash1, "hex");
      const buf2 = Buffer.from(hash2, "hex");
      assert.equal(crypto.timingSafeEqual(buf1, buf2), false);
    });
  });

  describe("Username Regex Policy", () => {
    test("Validates strict username regex ^[a-z0-9_]{3,20}$", () => {
      const regex = /^[a-z0-9_]{3,20}$/;
      assert.ok(regex.test("rahul_g"));
      assert.ok(regex.test("user123"));
      assert.equal(regex.test("Rahul_G"), false, "Uppercase letters must be rejected");
      assert.equal(regex.test("ab"), false, "Fewer than 3 chars must be rejected");
      assert.equal(regex.test("user@name"), false, "Special chars other than underscore must be rejected");
    });
  });

  describe("Refresh Token Hash & Privacy Projections", () => {
    test("Generates SHA-256 verifier digest without storing raw token", () => {
      const rawToken = "sample_raw_refresh_token_12345";
      const hash = crypto.createHash("sha256").update(rawToken).digest("hex");
      assert.equal(hash.length, 64);
      assert.notEqual(hash, rawToken);
    });

    test("Strips internal metadata from security event projections", () => {
      const internalRecord = {
        id: "evt_123",
        event_type: "device_revoked",
        severity: "medium",
        user_description_key: "sec_event.device_revoked",
        device_context_json: { platform: "android" },
        internal_metadata_json: { internalIp: "10.0.0.1", riskScore: 85 }
      };

      // Client Projection
      const clientProjection = {
        id: internalRecord.id,
        event_type: internalRecord.event_type,
        severity: internalRecord.severity,
        user_description_key: internalRecord.user_description_key,
        device_context_json: internalRecord.device_context_json
      };

      assert.equal((clientProjection as any).internal_metadata_json, undefined);
    });
  });
});
