import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { PrekeyService } from "../prekey.service.js";
import { PrekeysController } from "../prekeys.controller.js";

const user = randomUUID(),
  device = randomUUID(),
  target = randomUUID(),
  conversation = randomUUID();
const publicKey = Buffer.concat([Buffer.from([5]), Buffer.alloc(32, 7)]).toString("base64");
const body = () => ({
  protocolVersion: 1,
  registrationId: 42,
  identityPublicKeyBase64: publicKey,
  signedPrekeyId: 1,
  signedPrekeyPublicBase64: publicKey,
  signedPrekeySignatureBase64: Buffer.alloc(64, 9).toString("base64"),
  expiresAt: new Date(Date.now() + 3600000).toISOString(),
  oneTimePrekeys: [{ keyId: 1, publicKeyBase64: publicKey }]
});
function fixture(respond: (sql: string, values: unknown[]) => any[] = () => []) {
  const calls: string[] = [];
  let released = false;
  const service = new PrekeyService();
  Object.assign(service, {
    pool: {
      connect: async () => ({
        query: async (sql: string, values: unknown[] = []) => {
          calls.push(sql);
          return { rows: respond(sql, values) };
        },
        release: () => {
          released = true;
        }
      })
    }
  });
  return { service, calls, released: () => released };
}

test("invalid public material and batch IDs fail before database writes", async () => {
  for (const bad of [
    { protocolVersion: 2 },
    { identityPublicKeyBase64: "plaintext" },
    { signedPrekeySignatureBase64: publicKey },
    { registrationId: 0 },
    { expiresAt: new Date(0).toISOString() },
    {
      oneTimePrekeys: [
        { keyId: 1, publicKeyBase64: publicKey },
        { keyId: 1, publicKeyBase64: publicKey }
      ]
    }
  ]) {
    const f = fixture();
    await assert.rejects(f.service.publish(user, device, { ...body(), ...bad }));
    assert.equal(f.calls.length, 0);
  }
});

test("publication rejects revoked/unowned devices and rolls back", async () => {
  const f = fixture();
  await assert.rejects(f.service.publish(user, device, body()), /Active device/);
  assert.equal(f.calls.at(-1), "ROLLBACK");
  assert.equal(f.released(), true);
});

test("publication cannot silently replace identity or signed bundle", async () => {
  const b = body();
  const f = fixture((sql) =>
    sql.includes("SELECT d.id")
      ? [{ id: device }]
      : sql.includes("SELECT *")
        ? [{ registration_id: 43 }]
        : []
  );
  await assert.rejects(f.service.publish(user, device, b), /cannot be replaced/);
  assert.equal(f.calls.at(-1), "ROLLBACK");
  assert.equal(
    f.calls.some((s) => s.includes("INSERT")),
    false
  );
});

test("claim checks active device ownership before bundle lookup", async () => {
  const f = fixture();
  await assert.rejects(
    f.service.claim(user, device, conversation, target, randomUUID()),
    /Active device/
  );
  assert.equal(
    f.calls.some((s) => s.includes("device_key_bundles")),
    false
  );
  assert.equal(f.released(), true);
});

test("claim refuses nonmember before consuming a key", async () => {
  const f = fixture((sql) =>
    sql.includes("SELECT d.id")
      ? [
          { id: device, user_id: user },
          { id: target, user_id: randomUUID() }
        ]
      : []
  );
  await assert.rejects(
    f.service.claim(user, device, conversation, target, randomUUID()),
    /Both accounts/
  );
  assert.equal(
    f.calls.some((s) => s.includes("UPDATE")),
    false
  );
});

for (const retry of [false, true])
  test(`claim ${retry ? "retry" : "first request"} returns public bundle and commits`, async () => {
    const f = fixture((sql) => {
      if (sql.includes("SELECT d.id"))
        return [
          { id: device, user_id: user },
          { id: target, user_id: randomUUID() }
        ];
      if (sql.includes("conversation_members"))
        return [{ user_id: user }, { user_id: "recipient" }];
      if (sql.includes("SELECT *"))
        return [
          {
            protocol_version: 1,
            registration_id: 42,
            identity_key: Buffer.from(publicKey, "base64"),
            signed_prekey_id: 1,
            signed_prekey: Buffer.from(publicKey, "base64"),
            signed_prekey_signature: Buffer.alloc(64, 9),
            expires_at: new Date(Date.now() + 1000)
          }
        ];
      if (
        (retry && sql.includes("SELECT key_id")) ||
        (!retry && sql.includes("UPDATE device_one_time_prekeys"))
      )
        return [{ key_id: 5, public_key: Buffer.from(publicKey, "base64") }];
      return [];
    });
    const result = await f.service.claim(user, device, conversation, target, randomUUID());
    assert.equal(result.oneTimePrekeyId, 5);
    assert.equal(result.identityPublicKeyBase64, publicKey);
    assert.equal(
      f.calls.some((s) => s.includes("UPDATE device_one_time_prekeys")),
      !retry
    );
    assert.equal(f.calls.at(-1), "COMMIT");
    assert.equal(f.released(), true);
  });

test("controller derives publishing device from authenticated session", async () => {
  let args: unknown[] = [];
  const controller = new PrekeysController({
    publish: async (...values: unknown[]) => {
      args = values;
    }
  } as any);
  const b = { ...body(), deviceId: target };
  await controller.publish({ user: { userId: user, deviceId: device } }, b);
  assert.deepEqual(args, [user, device, b]);
});

test("publication rolls back when a prekey ID is rebound", async () => {
  const b = body();
  const f = fixture((sql) => {
    if (sql.includes("SELECT d.id")) return [{ id: device }];
    if (sql.includes("SELECT key_id, public_key")) return [{ public_key: Buffer.alloc(33, 2) }];
    return [];
  });
  await assert.rejects(f.service.publish(user, device, b), /cannot be rebound/);
  assert.equal(f.calls.at(-1), "ROLLBACK");
  assert.equal(f.released(), true);
});

test("exhausted or expired bundles never manufacture a successful claim", async () => {
  for (const expired of [false, true]) {
    const f = fixture((sql) => {
      if (sql.includes("SELECT d.id"))
        return [
          { id: device, user_id: user },
          { id: target, user_id: randomUUID() }
        ];
      if (sql.includes("conversation_members"))
        return [{ user_id: user }, { user_id: "recipient" }];
      if (sql.includes("SELECT *") && !expired) return [{}];
      return [];
    });
    await assert.rejects(
      f.service.claim(user, device, conversation, target, randomUUID()),
      expired ? /unavailable/ : /exhausted/
    );
    assert.equal(f.calls.at(-1), "ROLLBACK");
    assert.equal(f.released(), true);
  }
});
