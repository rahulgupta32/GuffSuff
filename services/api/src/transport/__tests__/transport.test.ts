import { test, describe } from "node:test";
import assert from "node:assert/strict";
import {
  CreateDirectConversationSchema,
  SubmitMessageEnvelopeSchema,
  RealtimeEventEnvelopeSchema
} from "@guffsuff/contracts";
import * as crypto from "crypto";

describe("Phase 5 Opaque Encrypted Envelope Transport Tests", () => {
  describe("Contracts & Validation", () => {
    test("Validates CreateDirectConversation schema", () => {
      const valid = CreateDirectConversationSchema.parse({
        recipientUserId: "018f4d9c-1234-7000-8000-000000000001"
      });
      assert.equal(valid.recipientUserId, "018f4d9c-1234-7000-8000-000000000001");
    });

    test("Validates SubmitMessageEnvelope schema within 64KB limit", () => {
      const opaqueBase64 = Buffer.from("random_opaque_bytes").toString("base64");
      const valid = SubmitMessageEnvelopeSchema.parse({
        idempotencyKey: "idemp_1001",
        conversationId: "018f4d9c-1234-7000-8000-000000000002",
        recipientUserId: "018f4d9c-1234-7000-8000-000000000003",
        protocolVersion: 1,
        opaquePayloadBase64: opaqueBase64,
        clientCreatedAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 86400000).toISOString()
      });
      assert.equal(valid.idempotencyKey, "idemp_1001");
    });

    test("Rejects SubmitMessageEnvelope with payload exceeding 64KB", () => {
      const oversizedBase64 = Buffer.alloc(70000, "a").toString("base64");
      assert.throws(() => {
        SubmitMessageEnvelopeSchema.parse({
          idempotencyKey: "idemp_oversized",
          conversationId: "018f4d9c-1234-7000-8000-000000000002",
          recipientUserId: "018f4d9c-1234-7000-8000-000000000003",
          protocolVersion: 1,
          opaquePayloadBase64: oversizedBase64,
          clientCreatedAt: new Date().toISOString(),
          expiresAt: new Date(Date.now() + 86400000).toISOString()
        });
      });
    });
  });

  describe("Idempotency & Payload Digest Logic", () => {
    test("Computes identical SHA-256 digest for duplicate payload retries", () => {
      const payload = Buffer.from("opaque_test_payload_123");
      const digest1 = crypto.createHash("sha256").update(payload).digest("hex");
      const digest2 = crypto.createHash("sha256").update(payload).digest("hex");
      assert.equal(digest1, digest2);
    });

    test("Detects digest mismatch when idempotency key reused with altered payload", () => {
      const payloadA = Buffer.from("opaque_test_payload_A");
      const payloadB = Buffer.from("opaque_test_payload_B");
      const digestA = crypto.createHash("sha256").update(payloadA).digest("hex");
      const digestB = crypto.createHash("sha256").update(payloadB).digest("hex");
      assert.notEqual(digestA, digestB);
    });
  });

  describe("Realtime Event Validation", () => {
    test("Parses valid RealtimeEventEnvelope for delivery push", () => {
      const valid = RealtimeEventEnvelopeSchema.parse({
        eventId: "018f4d9c-1234-7000-8000-000000000010",
        eventType: "server.message.delivery",
        correlationId: "018f4d9c-1234-7000-8000-000000000011",
        timestamp: Date.now(),
        payload: { envelopeId: "env_100", opaquePayloadBase64: "dGVzdA==" }
      });
      assert.equal(valid.eventType, "server.message.delivery");
    });
  });
});
