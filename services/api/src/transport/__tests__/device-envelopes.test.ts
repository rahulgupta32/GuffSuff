import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID, createHash } from "node:crypto";
import { MessageEnvelopeService } from "../message-envelope.service.js";

const sender = randomUUID(),
  recipient = randomUUID(),
  senderDevice = randomUUID(),
  targetA = randomUUID(),
  targetB = randomUUID(),
  conversation = randomUUID();
const dto = () => ({
  idempotencyKey: randomUUID(),
  conversationId: conversation,
  recipientUserId: recipient,
  protocolVersion: 2,
  clientCreatedAt: new Date().toISOString(),
  expiresAt: new Date(Date.now() + 3600000).toISOString(),
  deviceEnvelopes: [
    { recipientDeviceId: targetA, opaquePayloadBase64: "AQID" },
    { recipientDeviceId: targetB, opaquePayloadBase64: "BAUG" }
  ]
});
function fixture(
  options: {
    targets?: string[];
    membership?: boolean;
    cached?: any;
    revoked?: boolean;
    active?: boolean;
    failInsert?: boolean;
  } = {}
) {
  const calls: { sql: string; values: unknown[] }[] = [];
  let released = false;
  const service = new MessageEnvelopeService();
  Object.assign(service, {
    pool: {
      connect: async () => ({
        query: async (sql: string, values: unknown[] = []) => {
          calls.push({ sql, values });
          if (sql.includes("FROM users"))
            return { rows: options.active === false ? [] : [{ id: sender }, { id: recipient }] };
          if (sql.includes("FROM devices"))
            return {
              rows: [
                { id: senderDevice, user_id: sender, is_revoked: !!options.revoked },
                ...(options.targets ?? [targetA, targetB]).map((id) => ({
                  id,
                  user_id: recipient,
                  is_revoked: false
                }))
              ]
            };
          if (sql.includes("FROM conversation_members"))
            return {
              rows:
                options.membership === false ? [] : [{ user_id: sender }, { user_id: recipient }]
            };
          if (sql.includes("FROM message_idempotency_keys"))
            return { rows: options.cached ? [options.cached] : [] };
          if (sql.includes("INSERT INTO message_envelopes")) {
            if (options.failInsert) throw new Error("database unavailable");
            return { rows: [{ id: "persisted-envelope" }] };
          }
          return { rows: [] };
        },
        release: () => {
          released = true;
        }
      })
    }
  });
  return { service, calls, released: () => released };
}

test("separate ciphertext bytes are stored for each authorized recipient", async () => {
  const f = fixture(),
    input = dto();
  const result = await f.service.submitDeviceEnvelopes(sender, senderDevice, input);
  assert.equal(result.recipientDeviceCount, 2);
  const inserted = f.calls.filter((c) => c.sql.includes("INSERT INTO message_recipient_devices"));
  assert.equal(inserted.length, 2);
  for (const c of inserted) {
    const original = input.deviceEnvelopes.find((p) => p.recipientDeviceId === c.values[2])!;
    assert.deepEqual(c.values[3], Buffer.from(original.opaquePayloadBase64, "base64"));
  }
  assert.match(
    f.calls.find((c) => c.sql.includes("INSERT INTO message_envelopes"))!.sql,
    /NULL,'per_device'/
  );
  assert.equal(f.calls.at(-1)!.sql, "COMMIT");
  assert.equal(f.released(), true);
});

for (const options of [
  { targets: [targetA] },
  { targets: [targetA, targetB, randomUUID()] },
  { targets: [randomUUID(), targetB] },
  { membership: false },
  { revoked: true },
  { active: false }
])
  test(`unauthorized or changed target inventory rejects ${JSON.stringify(options)}`, async () => {
    const f = fixture(options);
    await assert.rejects(f.service.submitDeviceEnvelopes(sender, senderDevice, dto()));
    assert.equal(
      f.calls.some((c) => c.sql.includes("INSERT")),
      false
    );
    assert.equal(f.calls.at(-1)!.sql, "ROLLBACK");
  });

for (const bad of ["%%%", "AQID\n", ""])
  test(`malformed ciphertext rejected before network persistence ${JSON.stringify(bad)}`, async () => {
    const f = fixture(),
      input = dto();
    input.deviceEnvelopes[0]!.opaquePayloadBase64 = bad;
    await assert.rejects(f.service.submitDeviceEnvelopes(sender, senderDevice, input));
    assert.equal(f.calls.length, 0);
  });

test("duplicates and combined payload capacity fail before opening a transaction", async () => {
  for (const input of [
    {
      ...dto(),
      deviceEnvelopes: [
        { recipientDeviceId: targetA, opaquePayloadBase64: "AQID" },
        { recipientDeviceId: targetA.toUpperCase(), opaquePayloadBase64: "BAUG" }
      ]
    },
    {
      ...dto(),
      deviceEnvelopes: [
        { recipientDeviceId: targetA, opaquePayloadBase64: Buffer.alloc(40000).toString("base64") },
        { recipientDeviceId: targetB, opaquePayloadBase64: Buffer.alloc(40000).toString("base64") }
      ]
    }
  ]) {
    const f = fixture();
    await assert.rejects(f.service.submitDeviceEnvelopes(sender, senderDevice, input));
    assert.equal(f.calls.length, 0);
  }
});

test("database errors roll back without a successful acknowledgement", async () => {
  const f = fixture({ failInsert: true });
  await assert.rejects(
    f.service.submitDeviceEnvelopes(sender, senderDevice, dto()),
    /database unavailable/
  );
  assert.equal(f.calls.at(-1)!.sql, "ROLLBACK");
  assert.equal(f.released(), true);
});

test("matching retry preserves accepted inventory after a new recipient device joins", async () => {
  const input = dto();
  const payloads = input.deviceEnvelopes
    .map((p) => ({ id: p.recipientDeviceId, bytes: p.opaquePayloadBase64 }))
    .sort((a, b) => a.id.localeCompare(b.id));
  const digest = createHash("sha256")
    .update("guffsuff/per-device/v1\0")
    .update(
      JSON.stringify({
        conversationId: conversation,
        recipientUserId: recipient,
        protocolVersion: 2,
        clientCreatedAt: input.clientCreatedAt,
        expiresAt: input.expiresAt,
        payloads: payloads.map((p) => [p.id, p.bytes])
      })
    )
    .digest("hex");
  const f = fixture({
    targets: [targetA, targetB, randomUUID()],
    cached: { id: "accepted", payload_mode: "per_device", payload_digest_sha256: digest }
  });
  const result = await f.service.submitDeviceEnvelopes(sender, senderDevice, {
    ...input,
    deviceEnvelopes: [...input.deviceEnvelopes].reverse()
  });
  assert.equal(result.idempotentRetry, true);
  assert.equal(result.recipientDeviceCount, 2);
  assert.equal(
    f.calls.some((c) => c.sql.includes("INSERT")),
    false
  );
});

test("changed retry metadata or ciphertext cannot rebind an accepted batch", async () => {
  const f = fixture({ cached: { payload_mode: "per_device", payload_digest_sha256: "different" } });
  await assert.rejects(
    f.service.submitDeviceEnvelopes(sender, senderDevice, dto()),
    /changed device payloads/
  );
  assert.equal(f.calls.at(-1)!.sql, "ROLLBACK");
});

test("recipient device discovery rejects an unauthorized caller before enumerating devices", async () => {
  const service = new MessageEnvelopeService();
  let calls = 0;
  Object.assign(service, {
    pool: {
      query: async () => {
        calls++;
        return { rows: [] };
      }
    }
  });
  await assert.rejects(
    service.listRecipientDevices(sender, senderDevice, conversation, recipient),
    /unauthorized/
  );
  assert.equal(calls, 1);
});

test("authorized device discovery returns only active device identifiers", async () => {
  const service = new MessageEnvelopeService();
  const queries: string[] = [];
  Object.assign(service, {
    pool: {
      query: async (sql: string) => {
        queries.push(sql);
        return {
          rows: queries.length === 1 ? [{ id: senderDevice }] : [{ id: targetA }, { id: targetB }]
        };
      }
    }
  });
  assert.deepEqual(
    await service.listRecipientDevices(sender, senderDevice, conversation, recipient),
    [{ id: targetA }, { id: targetB }]
  );
  assert.match(queries[0]!, /d.user_id=\$2/);
  assert.match(queries[1]!, /NOT is_revoked/);
});
