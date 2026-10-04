import { test } from "node:test";
import assert from "node:assert/strict";
import { MessageEnvelopeService } from "../message-envelope.service.js";
import { EnvelopesController } from "../envelopes.controller.js";

const envelopeId = "018f4d9c-1234-7000-8000-000000000001";
function fixture(respond: (sql: string, values: unknown[]) => unknown[] = () => []) {
  const calls: { sql: string; values: unknown[] }[] = [];
  let released = false;
  const query = async (sql: string, values: unknown[] = []) => {
    calls.push({ sql, values });
    return { rows: respond(sql, values) };
  };
  const service = new MessageEnvelopeService();
  Object.assign(service, {
    pool: {
      query,
      connect: async () => ({
        query,
        release: () => {
          released = true;
        }
      })
    }
  });
  return { service, calls, released: () => released };
}
const dto = {
  idempotencyKey: "key",
  conversationId: "conversation",
  recipientUserId: "recipient",
  protocolVersion: 1,
  opaquePayloadBase64: "dGVzdA==",
  clientCreatedAt: new Date().toISOString(),
  expiresAt: new Date(Date.now() + 60000).toISOString()
};
test("pending controller forwards the requested conversation and authenticated device", async () => {
  const f = fixture();
  await new EnvelopesController(f.service).getPendingEnvelopes(
    { user: { userId: "user", deviceId: "device" } },
    "conversation"
  );
  assert.deepEqual(f.calls[0]!.values, ["device", "user", "conversation"]);
  assert.match(f.calls[0]!.sql, /e.conversation_id = \$3/);
  assert.match(f.calls[0]!.sql, /NOT d.is_revoked/);
});
test("read controller rejects a body envelope that differs from the URL", async () => {
  const f = fixture();
  await assert.rejects(
    new EnvelopesController(f.service).acknowledgeRead(
      { user: { userId: "user", deviceId: "device" } },
      envelopeId,
      { lastReadEnvelopeId: "018f4d9c-1234-7000-8000-000000000002" }
    ),
    /must match/
  );
  assert.equal(f.calls.length, 0);
});
test("unauthorized read receipts roll back without updating read state", async () => {
  const f = fixture();
  await assert.rejects(f.service.acknowledgeRead("user", "device", envelopeId), /unauthorized/);
  assert.equal(f.calls.at(-1)?.sql, "ROLLBACK");
  assert.equal(
    f.calls.some((c) => c.sql.includes("UPDATE message_recipient_devices")),
    false
  );
  assert.equal(f.released(), true);
});
test("read controller resolves conversation from authorized envelope and commits receipt", async () => {
  const f = fixture((sql) =>
    sql.includes("SELECT e.conversation_id") ? [{ conversation_id: "resolved-conversation" }] : []
  );
  const result = await new EnvelopesController(f.service).acknowledgeRead(
    { user: { userId: "user", deviceId: "device" } },
    envelopeId,
    { lastReadEnvelopeId: envelopeId }
  );
  assert.equal(result.conversationId, "resolved-conversation");
  assert.deepEqual(f.calls[1]!.values, [envelopeId, "user", "device"]);
  assert.match(f.calls[1]!.sql, /FOR UPDATE OF rd/);
  assert.match(
    f.calls.find((c) => c.sql.includes("INSERT INTO message_read_states"))!.sql,
    /server_accepted_at, id/
  );
  assert.equal(f.calls.at(-1)?.sql, "COMMIT");
});
test("submission rejects recipients outside the conversation before persisting", async () => {
  const f = fixture((sql, values) =>
    sql.includes("SELECT id, is_revoked")
      ? [{ id: "device", is_revoked: false }]
      : sql.includes("FROM conversation_members") && values[1] === "sender"
        ? [{ conversation_id: "conversation" }]
        : []
  );
  await assert.rejects(f.service.submitEnvelope("sender", "device", dto), /not a peer/);
  assert.equal(
    f.calls.some((c) => c.sql.includes("INSERT")),
    false
  );
});
for (const payload of ["%%%", "dGVzdA", "dGVzdA==\n"]) {
  test(`submission rejects malformed or noncanonical base64 ${JSON.stringify(payload)}`, async () => {
    const f = fixture((sql) =>
      sql.includes("SELECT id, is_revoked")
        ? [{ is_revoked: false }]
        : [{ conversation_id: "conversation" }]
    );
    await assert.rejects(
      f.service.submitEnvelope("sender", "device", { ...dto, opaquePayloadBase64: payload }),
      /canonical/
    );
    assert.equal(
      f.calls.some((c) => c.sql.includes("INSERT")),
      false
    );
  });
}
test("submission rejects expired envelopes", async () => {
  const f = fixture((sql) =>
    sql.includes("SELECT id, is_revoked")
      ? [{ is_revoked: false }]
      : sql.includes("FROM conversation_members")
        ? [{ conversation_id: "conversation" }]
        : []
  );
  await assert.rejects(
    f.service.submitEnvelope("sender", "device", { ...dto, expiresAt: new Date(0).toISOString() }),
    /future/
  );
});
test("idempotent retry cannot change conversation routing", async () => {
  const digest = (await import("node:crypto"))
    .createHash("sha256")
    .update(Buffer.from("test"))
    .digest("hex");
  const f = fixture((sql) =>
    sql.includes("SELECT id, is_revoked")
      ? [{ is_revoked: false }]
      : sql.includes("FROM conversation_members")
        ? [{ conversation_id: "conversation" }]
        : sql.includes("FROM message_idempotency_keys")
          ? [{ envelope_id: envelopeId, payload_digest_sha256: digest }]
          : [
              {
                conversation_id: "another-conversation",
                recipient_user_id: "recipient",
                protocol_version: 1
              }
            ]
  );
  await assert.rejects(f.service.submitEnvelope("sender", "device", dto), /different routing/);
});
test("delivery retries preserve an existing read receipt", async () => {
  const f = fixture((sql) =>
    sql.includes("SELECT rd.id")
      ? [{ id: "receipt", delivery_status: "read", recipient_user_id: "user" }]
      : []
  );
  await f.service.acknowledgeDelivery("user", "device", envelopeId);
  const update = f.calls.find((c) => c.sql.includes("UPDATE message_recipient_devices"))!;
  assert.match(update.sql, /WHEN delivery_status = 'read' THEN 'read'/);
  assert.match(update.sql, /COALESCE\(delivered_at/);
});

test("submission checks idempotency under a sender-device row lock and commits cached retries", async () => {
  const digest = (await import("node:crypto"))
    .createHash("sha256")
    .update(Buffer.from("test"))
    .digest("hex");
  const f = fixture((sql) =>
    sql.includes("SELECT id, is_revoked")
      ? [{ is_revoked: false }]
      : sql.includes("FROM conversation_members")
        ? [{ conversation_id: "conversation" }]
        : sql.includes("FROM message_idempotency_keys")
          ? [{ envelope_id: envelopeId, payload_digest_sha256: digest }]
          : sql.includes("FROM message_envelopes")
            ? [
                {
                  id: envelopeId,
                  conversation_id: "conversation",
                  recipient_user_id: "recipient",
                  protocol_version: 1
                }
              ]
            : []
  );
  const result = await f.service.submitEnvelope("sender", "device", dto);
  assert.equal(result.idempotentRetry, true);
  assert.equal(f.calls[0]!.sql, "BEGIN");
  assert.match(f.calls[1]!.sql, /FOR UPDATE/);
  assert.equal(f.calls.at(-1)!.sql, "COMMIT");
  assert.equal(f.released(), true);
});
test("an accepted envelope retry remains idempotent after its expiry", async () => {
  const digest = (await import("node:crypto"))
    .createHash("sha256")
    .update(Buffer.from("test"))
    .digest("hex");
  const f = fixture((sql) =>
    sql.includes("SELECT id, is_revoked")
      ? [{ is_revoked: false }]
      : sql.includes("FROM conversation_members")
        ? [{ conversation_id: "conversation" }]
        : sql.includes("FROM message_idempotency_keys")
          ? [{ envelope_id: envelopeId, payload_digest_sha256: digest }]
          : sql.includes("FROM message_envelopes")
            ? [
                {
                  id: envelopeId,
                  conversation_id: "conversation",
                  recipient_user_id: "recipient",
                  protocol_version: 1
                }
              ]
            : []
  );
  const result = await f.service.submitEnvelope("sender", "device", {
    ...dto,
    expiresAt: new Date(0).toISOString()
  });
  assert.equal(result.idempotentRetry, true);
  assert.equal(
    f.calls.some((c) => c.sql.includes("INSERT")),
    false
  );
});
test("a submission error rolls back and releases its sender-device lock", async () => {
  const f = fixture();
  await assert.rejects(f.service.submitEnvelope("sender", "device", dto), /invalid or revoked/);
  assert.equal(f.calls.at(-1)!.sql, "ROLLBACK");
  assert.equal(f.released(), true);
});

test("pending fetch is bounded and has deterministic tie ordering", async () => {
  const f = fixture();
  await f.service.getPendingEnvelopes("user", "device", "conversation");
  assert.match(f.calls[0]!.sql, /ORDER BY e.server_accepted_at ASC, e.id ASC/);
  assert.match(f.calls[0]!.sql, /LIMIT 100/);
});
test("delivery authorization and audit receipt occur in one locked transaction", async () => {
  const f = fixture((sql) =>
    sql.includes("SELECT rd.id")
      ? [{ id: "receipt", recipient_user_id: "user", delivery_status: "delivered" }]
      : []
  );
  await f.service.acknowledgeDelivery("user", "device", envelopeId);
  assert.equal(f.calls[0]!.sql, "BEGIN");
  assert.match(f.calls[1]!.sql, /FOR UPDATE OF rd/);
  assert.match(f.calls[1]!.sql, /FROM conversation_members/);
  const audit = f.calls.find((c) => c.sql.includes("INSERT INTO message_acknowledgements"))!;
  assert.match(audit.sql, /ON CONFLICT \(envelope_id, recipient_device_id, ack_type\) DO NOTHING/);
  assert.equal(f.calls.at(-1)!.sql, "COMMIT");
});
test("unauthorized delivery rolls back without changing status or audit rows", async () => {
  const f = fixture();
  await assert.rejects(f.service.acknowledgeDelivery("user", "device", envelopeId), /unauthorized/);
  assert.equal(f.calls.at(-1)!.sql, "ROLLBACK");
  assert.equal(
    f.calls.some((c) => /^\s*(INSERT|UPDATE)\b/.test(c.sql)),
    false
  );
  assert.equal(f.released(), true);
});
test("read receipt writes a deduplicated audit row before committing", async () => {
  const f = fixture((sql) =>
    sql.includes("SELECT e.conversation_id") ? [{ conversation_id: "conversation" }] : []
  );
  await f.service.acknowledgeRead("user", "device", envelopeId);
  const audit = f.calls.find((c) => c.sql.includes("INSERT INTO message_acknowledgements"))!;
  assert.match(audit.sql, /'read'/);
  assert.match(audit.sql, /ON CONFLICT/);
  assert.deepEqual(audit.values.slice(1), [envelopeId, "device"]);
});
