import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { createDatabasePool } from "../packages/database/dist/index.js";
import { ConversationService } from "../services/api/dist/transport/conversation.service.js";
import { MessageEnvelopeService } from "../services/api/dist/transport/message-envelope.service.js";

if (process.env.GUFFSUFF_INTEGRATION_DATABASE !== "true" || !process.env.DATABASE_URL) {
  throw new Error("Run only against an explicitly selected isolated integration database.");
}
import { PrekeyService } from "../services/api/dist/transport/prekey.service.js";

const pool = createDatabasePool();
const conversations = new ConversationService();
const envelopes = new MessageEnvelopeService();
const prekeys = new PrekeyService();
const sender = randomUUID(),
  recipient = randomUUID();
const senderDevice = randomUUID(),
  recipientDevice = randomUUID();
try {
  for (const user of [sender, recipient]) {
    await pool.query(
      `INSERT INTO users(id, account_state, terms_accepted_at, privacy_accepted_at)
      VALUES ($1, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
      [user]
    );
  }
  for (const [device, user] of [
    [senderDevice, sender],
    [recipientDevice, recipient]
  ]) {
    await pool.query(
      `INSERT INTO devices(id, user_id, installation_id, device_name, platform, app_version, os_version)
      VALUES ($1, $2, $3, 'Integration test', 'android', 'test', 'test')`,
      [device, user, device]
    );
  }
  const created = await Promise.all(
    Array.from({ length: 8 }, (_, i) =>
      i % 2
        ? conversations.getOrCreateDirectConversation(sender, recipient)
        : conversations.getOrCreateDirectConversation(recipient, sender)
    )
  );
  assert.equal(new Set(created.map((c) => c.id)).size, 1);
  const conversation = created[0].id;
  const members = await pool.query(
    "SELECT user_id FROM conversation_members WHERE conversation_id = $1",
    [conversation]
  );
  assert.equal(members.rows.length, 2);
  const dto = {
    conversationId: conversation,
    recipientUserId: recipient,
    idempotencyKey: randomUUID(),
    protocolVersion: 1,
    opaquePayloadBase64: Buffer.from([1, 2, 3]).toString("base64"),
    clientCreatedAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + 3600000).toISOString()
  };
  const accepted = await Promise.all(
    Array.from({ length: 8 }, () => envelopes.submitEnvelope(sender, senderDevice, dto))
  );
  assert.equal(new Set(accepted.map((e) => e.id)).size, 1);
  assert.equal(accepted.filter((e) => !e.idempotentRetry).length, 1);
  const envelope = accepted[0].id;
  assert.equal(
    (await envelopes.getPendingEnvelopes(recipient, recipientDevice, conversation)).length,
    1
  );
  await Promise.all(
    Array.from({ length: 8 }, () =>
      envelopes.acknowledgeDelivery(recipient, recipientDevice, envelope)
    )
  );
  await Promise.all(
    Array.from({ length: 8 }, () => envelopes.acknowledgeRead(recipient, recipientDevice, envelope))
  );
  await envelopes.acknowledgeDelivery(recipient, recipientDevice, envelope);
  const receipts = await pool.query(
    "SELECT ack_type FROM message_acknowledgements WHERE envelope_id = $1",
    [envelope]
  );
  assert.deepEqual(receipts.rows.map((r) => r.ack_type).sort(), ["delivery", "read"]);
  const status = await envelopes.getEnvelopeStatus(sender, envelope);
  assert.equal(status.recipientDevices[0].delivery_status, "read");
  assert.equal(
    (await envelopes.getPendingEnvelopes(recipient, recipientDevice, conversation)).length,
    0
  );
  // Structural fixtures only; these bytes are not real signed cryptographic material.
  const publicKey = Buffer.concat([Buffer.from([5]), Buffer.alloc(32, 7)]).toString("base64");
  const bundle = {
    protocolVersion: 1,
    registrationId: 42,
    identityPublicKeyBase64: publicKey,
    signedPrekeyId: 1,
    signedPrekeyPublicBase64: publicKey,
    signedPrekeySignatureBase64: Buffer.alloc(64, 9).toString("base64"),
    expiresAt: new Date(Date.now() + 3600000).toISOString(),
    oneTimePrekeys: [1, 2, 3].map((keyId) => ({
      keyId,
      publicKeyBase64: Buffer.concat([Buffer.from([5]), Buffer.alloc(32, keyId)]).toString("base64")
    }))
  };
  assert.equal((await prekeys.publish(recipient, recipientDevice, bundle)).availablePrekeys, 3);
  const claimId = randomUUID();
  const claims = await Promise.all(
    Array.from({ length: 8 }, () =>
      prekeys.claim(sender, senderDevice, conversation, recipientDevice, claimId)
    )
  );
  assert.equal(new Set(claims.map((c) => c.oneTimePrekeyId)).size, 1);
  const distinct = await Promise.all(
    Array.from({ length: 2 }, () =>
      prekeys.claim(sender, senderDevice, conversation, recipientDevice, randomUUID())
    )
  );
  assert.equal(new Set([...claims, ...distinct].map((c) => c.oneTimePrekeyId)).size, 3);
  await assert.rejects(
    prekeys.claim(sender, senderDevice, conversation, recipientDevice, randomUUID()),
    /exhausted/
  );
  assert.equal((await prekeys.publish(recipient, recipientDevice, bundle)).availablePrekeys, 0);
  // Consumed keys must remain consumed when a requesting device is deleted.
  await pool.query("DELETE FROM devices WHERE id = $1", [senderDevice]);
  assert.equal((await prekeys.publish(recipient, recipientDevice, bundle)).availablePrekeys, 0);
  assert.equal(
    (
      await pool.query(
        "SELECT COUNT(*)::int AS count FROM device_one_time_prekeys WHERE device_id = $1 AND claim_id IS NOT NULL",
        [recipientDevice]
      )
    ).rows[0].count,
    3
  );
  await pool.query("UPDATE devices SET is_revoked = true WHERE id = $1", [recipientDevice]);
  await assert.rejects(prekeys.publish(recipient, recipientDevice, bundle), /Active device/);
  console.log(
    "PostgreSQL prekey integration passed: concurrent claim retries, distinct allocation, exhaustion, consumed-key replenishment and deletion/revocation safety."
  );
  console.log(
    "PostgreSQL integration passed: concurrent conversations, envelope retries, receipts and pending retrieval."
  );
} finally {
  // Remove only records owned by these generated fixture users.
  try {
    await pool.query("DELETE FROM users WHERE id = ANY($1::uuid[])", [[sender, recipient]]);
  } finally {
    await Promise.all([
      pool.end(),
      conversations.pool.end(),
      envelopes.pool.end(),
      prekeys.pool.end()
    ]);
  }
}
