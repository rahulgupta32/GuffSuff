import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException
} from "@nestjs/common";
import { createDatabasePool } from "@guffsuff/database";
import { generateUUIDv7 } from "@guffsuff/id-generation";
import {
  SubmitMessageEnvelope,
  SubmitDeviceEnvelopesSchema,
  SubmitDeviceEnvelopes
} from "@guffsuff/contracts";
import * as crypto from "crypto";

@Injectable()
export class MessageEnvelopeService {
  private pool = createDatabasePool();

  async submitEnvelope(senderUserId: string, senderDeviceId: string, dto: SubmitMessageEnvelope) {
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");
      // 1. Verify sender device is active
      const deviceRes = await client.query(
        "SELECT id, is_revoked FROM devices WHERE id = $1 AND user_id = $2 FOR UPDATE",
        [senderDeviceId, senderUserId]
      );
      if (deviceRes.rows.length === 0 || deviceRes.rows[0].is_revoked) {
        throw new ForbiddenException("Sender device is invalid or revoked");
      }

      // 2. Verify conversation membership
      const memberRes = await client.query(
        "SELECT conversation_id FROM conversation_members WHERE conversation_id = $1 AND user_id = $2",
        [dto.conversationId, senderUserId]
      );
      if (memberRes.rows.length === 0) {
        throw new ForbiddenException("Access denied to conversation");
      }

      const recipientMember = await client.query(
        "SELECT conversation_id FROM conversation_members WHERE conversation_id = $1 AND user_id = $2",
        [dto.conversationId, dto.recipientUserId]
      );
      if (senderUserId === dto.recipientUserId || recipientMember.rows.length === 0) {
        throw new ForbiddenException("Recipient is not a peer in this conversation");
      }

      // 3. Compute payload digest and check payload length
      const opaqueBuffer = Buffer.from(dto.opaquePayloadBase64, "base64");
      if (
        opaqueBuffer.length === 0 ||
        opaqueBuffer.toString("base64") !== dto.opaquePayloadBase64
      ) {
        throw new BadRequestException("Opaque payload must be canonical nonempty base64");
      }
      if (opaqueBuffer.length > 65536) {
        throw new BadRequestException("Opaque payload exceeds maximum allowed size of 64KB");
      }

      const payloadDigest = crypto.createHash("sha256").update(opaqueBuffer).digest("hex");

      // 4. Check idempotency key
      const idempRes = await client.query(
        "SELECT envelope_id, payload_digest_sha256 FROM message_idempotency_keys WHERE sender_device_id = $1 AND idempotency_key = $2",
        [senderDeviceId, dto.idempotencyKey]
      );

      if (idempRes.rows.length > 0) {
        const existing = idempRes.rows[0];
        if (existing.payload_digest_sha256 !== payloadDigest) {
          throw new BadRequestException("Idempotency key reused with different payload digest");
        }

        // Return cached envelope response
        const cachedEnv = await client.query(
          "SELECT id, conversation_id, sender_user_id, sender_device_id, recipient_user_id, protocol_version, payload_byte_length, server_accepted_at, expires_at FROM message_envelopes WHERE id = $1",
          [existing.envelope_id]
        );
        const cached = cachedEnv.rows[0];
        if (
          !cached ||
          cached.conversation_id !== dto.conversationId ||
          cached.recipient_user_id !== dto.recipientUserId ||
          cached.protocol_version !== dto.protocolVersion
        ) {
          throw new BadRequestException(
            "Idempotency key reused with different routing or protocol"
          );
        }
        await client.query("COMMIT");
        return {
          ...cached,
          idempotentRetry: true
        };
      }

      if (
        !Number.isFinite(new Date(dto.expiresAt).getTime()) ||
        new Date(dto.expiresAt).getTime() <= Date.now()
      ) {
        throw new BadRequestException("Envelope expiry must be in the future");
      }

      // 5. Resolve active recipient devices
      const recipientDevicesRes = await client.query(
        "SELECT id FROM devices WHERE user_id = $1 AND is_revoked = false",
        [dto.recipientUserId]
      );

      const envelopeId = generateUUIDv7();
      const idempRecordId = generateUUIDv7();

      // Insert envelope
      const insertEnv = await client.query(
        `INSERT INTO message_envelopes (
          id, client_idempotency_key, conversation_id, sender_user_id, sender_device_id,
          recipient_user_id, protocol_version, payload_byte_length, opaque_payload,
          client_created_at, expires_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING id, conversation_id, sender_user_id, sender_device_id, recipient_user_id, protocol_version, payload_byte_length, server_accepted_at, expires_at`,
        [
          envelopeId,
          dto.idempotencyKey,
          dto.conversationId,
          senderUserId,
          senderDeviceId,
          dto.recipientUserId,
          dto.protocolVersion,
          opaqueBuffer.length,
          opaqueBuffer,
          dto.clientCreatedAt,
          dto.expiresAt
        ]
      );

      // Insert idempotency key
      await client.query(
        `INSERT INTO message_idempotency_keys (id, sender_device_id, idempotency_key, envelope_id, payload_digest_sha256)
         VALUES ($1, $2, $3, $4, $5)`,
        [idempRecordId, senderDeviceId, dto.idempotencyKey, envelopeId, payloadDigest]
      );

      // Insert recipient device records
      for (const dev of recipientDevicesRes.rows) {
        const rdId = generateUUIDv7();
        await client.query(
          `INSERT INTO message_recipient_devices (id, envelope_id, recipient_device_id, delivery_status)
           VALUES ($1, $2, $3, 'accepted')`,
          [rdId, envelopeId, dev.id]
        );
      }

      await client.query("COMMIT");
      return {
        ...insertEnv.rows[0],
        recipientDeviceCount: recipientDevicesRes.rows.length,
        idempotentRetry: false
      };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  async listRecipientDevices(
    userId: string,
    deviceId: string,
    conversationId: string,
    recipientUserId: string
  ) {
    const ids = [userId, deviceId, conversationId, recipientUserId];
    if (
      !ids.every((value) =>
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)
      )
    )
      throw new BadRequestException("Invalid identifier");
    if (userId.toLowerCase() === recipientUserId.toLowerCase())
      throw new BadRequestException("Recipient must be another account");
    const access = await this.pool.query(
      `SELECT d.id FROM devices d JOIN users u ON u.id = d.user_id
      WHERE d.id=$1 AND d.user_id=$2 AND NOT d.is_revoked AND u.account_state='active'
      AND EXISTS (SELECT 1 FROM users peer WHERE peer.id=$4 AND peer.account_state='active')
      AND EXISTS (SELECT 1 FROM conversation_members m WHERE m.conversation_id=$3 AND m.user_id=$2)
      AND EXISTS (SELECT 1 FROM conversation_members m WHERE m.conversation_id=$3 AND m.user_id=$4)`,
      [deviceId, userId, conversationId, recipientUserId]
    );
    if (!access.rows.length)
      throw new ForbiddenException("Recipient device discovery unauthorized");
    return (
      await this.pool.query(
        "SELECT id FROM devices WHERE user_id=$1 AND NOT is_revoked ORDER BY id",
        [recipientUserId]
      )
    ).rows;
  }

  async submitDeviceEnvelopes(
    senderUserId: string,
    senderDeviceId: string,
    input: SubmitDeviceEnvelopes
  ) {
    const parsed = SubmitDeviceEnvelopesSchema.safeParse(input);
    if (!parsed.success) throw new BadRequestException("Invalid per-device envelope request");
    const dto = parsed.data;
    dto.conversationId = dto.conversationId.toLowerCase();
    dto.recipientUserId = dto.recipientUserId.toLowerCase();
    senderUserId = senderUserId.toLowerCase();
    senderDeviceId = senderDeviceId.toLowerCase();
    const payloads = dto.deviceEnvelopes
      .map((item) => {
        const bytes = Buffer.from(item.opaquePayloadBase64, "base64");
        if (!bytes.length || bytes.toString("base64") !== item.opaquePayloadBase64)
          throw new BadRequestException("Ciphertext must be canonical nonempty base64");
        return { deviceId: item.recipientDeviceId.toLowerCase(), bytes };
      })
      .sort((a, b) => a.deviceId.localeCompare(b.deviceId));
    if (new Set(payloads.map((p) => p.deviceId)).size !== payloads.length)
      throw new BadRequestException("Duplicate recipient device");
    const total = payloads.reduce((sum, p) => sum + p.bytes.length, 0);
    if (total > 65536) throw new BadRequestException("Combined ciphertext exceeds 64KB");
    const digest = crypto
      .createHash("sha256")
      .update("guffsuff/per-device/v1\0")
      .update(
        JSON.stringify({
          conversationId: dto.conversationId.toLowerCase(),
          recipientUserId: dto.recipientUserId.toLowerCase(),
          protocolVersion: dto.protocolVersion,
          clientCreatedAt: dto.clientCreatedAt,
          expiresAt: dto.expiresAt,
          payloads: payloads.map((p) => [p.deviceId, p.bytes.toString("base64")])
        })
      )
      .digest("hex");
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");
      if (senderUserId === dto.recipientUserId)
        throw new ForbiddenException("Recipient must be another account");
      const users = await client.query(
        "SELECT id FROM users WHERE id = ANY($1::uuid[]) AND account_state = 'active' ORDER BY id FOR SHARE",
        [[senderUserId, dto.recipientUserId]]
      );
      if (users.rows.length !== 2) throw new ForbiddenException("Both accounts must be active");
      // Lock in global device order, including the sender, to avoid crossed-send deadlocks.
      const devices = await client.query(
        `SELECT id, user_id, is_revoked FROM devices
        WHERE id = $1 OR (user_id = $2 AND NOT is_revoked) ORDER BY id FOR UPDATE`,
        [senderDeviceId, dto.recipientUserId]
      );
      const sender = devices.rows.find((d) => d.id === senderDeviceId);
      if (!sender || sender.user_id !== senderUserId || sender.is_revoked)
        throw new ForbiddenException("Sender device is invalid or revoked");
      if (senderUserId === dto.recipientUserId)
        throw new ForbiddenException("Recipient must be another account");
      const members = await client.query(
        "SELECT user_id FROM conversation_members WHERE conversation_id = $1 AND user_id = ANY($2::uuid[]) FOR SHARE",
        [dto.conversationId, [senderUserId, dto.recipientUserId]]
      );
      if (members.rows.length !== 2)
        throw new ForbiddenException("Both accounts must belong to the conversation");
      const cached = (
        await client.query(
          `SELECT k.payload_digest_sha256, e.id, e.payload_mode, e.conversation_id, e.sender_user_id, e.sender_device_id,
        e.recipient_user_id, e.protocol_version, e.payload_byte_length, e.server_accepted_at, e.expires_at
        FROM message_idempotency_keys k JOIN message_envelopes e ON e.id = k.envelope_id
        WHERE k.sender_device_id = $1 AND k.idempotency_key = $2`,
          [senderDeviceId, dto.idempotencyKey]
        )
      ).rows[0];
      if (cached) {
        if (cached.payload_mode !== "per_device" || cached.payload_digest_sha256 !== digest)
          throw new BadRequestException(
            "Idempotency key reused with changed device payloads or metadata"
          );
        const { payload_digest_sha256: _digest, ...response } = cached;
        await client.query("COMMIT");
        return { ...response, recipientDeviceCount: payloads.length, idempotentRetry: true };
      }
      if (new Date(dto.expiresAt).getTime() <= Date.now())
        throw new BadRequestException("Envelope expiry must be in the future");
      const targets = devices.rows
        .filter((d) => d.user_id === dto.recipientUserId && !d.is_revoked)
        .map((d) => d.id)
        .sort();
      if (
        targets.length !== payloads.length ||
        targets.some((id, i) => id !== payloads[i]?.deviceId)
      )
        throw new BadRequestException(
          "Ciphertext must cover exactly the active recipient devices; refresh the device list"
        );
      const envelopeId = generateUUIDv7();
      const result = await client.query(
        `INSERT INTO message_envelopes (id, client_idempotency_key, conversation_id, sender_user_id, sender_device_id,
        recipient_user_id, protocol_version, payload_byte_length, opaque_payload, payload_mode, client_created_at, expires_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NULL,'per_device',$9,$10)
        RETURNING id, conversation_id, sender_user_id, sender_device_id, recipient_user_id, protocol_version, payload_byte_length, payload_mode, server_accepted_at, expires_at`,
        [
          envelopeId,
          dto.idempotencyKey,
          dto.conversationId,
          senderUserId,
          senderDeviceId,
          dto.recipientUserId,
          dto.protocolVersion,
          total,
          dto.clientCreatedAt,
          dto.expiresAt
        ]
      );
      await client.query(
        "INSERT INTO message_idempotency_keys (id, sender_device_id, idempotency_key, envelope_id, payload_digest_sha256) VALUES ($1,$2,$3,$4,$5)",
        [generateUUIDv7(), senderDeviceId, dto.idempotencyKey, envelopeId, digest]
      );
      for (const payload of payloads)
        await client.query(
          `INSERT INTO message_recipient_devices (id,envelope_id,recipient_device_id,delivery_status,opaque_payload)
        VALUES ($1,$2,$3,'accepted',$4)`,
          [generateUUIDv7(), envelopeId, payload.deviceId, payload.bytes]
        );
      await client.query("COMMIT");
      return { ...result.rows[0], recipientDeviceCount: payloads.length, idempotentRetry: false };
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  async getPendingEnvelopes(userId: string, deviceId: string, conversationId: string) {
    const res = await this.pool.query(
      `SELECT e.id, e.conversation_id, e.sender_user_id, e.sender_device_id, e.recipient_user_id,
              e.protocol_version, octet_length(CASE WHEN e.payload_mode = 'per_device' THEN rd.opaque_payload ELSE e.opaque_payload END) AS payload_byte_length,
              encode(CASE WHEN e.payload_mode = 'per_device' THEN rd.opaque_payload ELSE e.opaque_payload END, 'base64') AS opaque_payload_base64,
              e.client_created_at, e.server_accepted_at, e.expires_at, rd.delivery_status
       FROM message_envelopes e
       JOIN message_recipient_devices rd ON e.id = rd.envelope_id
       WHERE rd.recipient_device_id = $1 AND e.recipient_user_id = $2
         AND (e.payload_mode = 'shared' OR rd.opaque_payload IS NOT NULL)
         AND rd.delivery_status IN ('accepted', 'queued', 'routed')
         AND e.expires_at > CURRENT_TIMESTAMP
         AND e.conversation_id = $3
         AND EXISTS (SELECT 1 FROM devices d WHERE d.id = $1 AND d.user_id = $2 AND NOT d.is_revoked)
         AND EXISTS (SELECT 1 FROM conversation_members m WHERE m.conversation_id = $3 AND m.user_id = $2)
       ORDER BY e.server_accepted_at ASC, e.id ASC
       LIMIT 100`,
      [deviceId, userId, conversationId]
    );
    return res.rows;
  }

  async acknowledgeDelivery(userId: string, deviceId: string, envelopeId: string) {
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");
      const rdRes = await client.query(
        `SELECT rd.id, rd.delivery_status, e.recipient_user_id
       FROM message_recipient_devices rd
       JOIN message_envelopes e ON rd.envelope_id = e.id
       WHERE rd.envelope_id = $1 AND rd.recipient_device_id = $2
         AND EXISTS (SELECT 1 FROM devices d WHERE d.id = $2 AND d.user_id = $3 AND NOT d.is_revoked)
         AND EXISTS (SELECT 1 FROM conversation_members m WHERE m.conversation_id = e.conversation_id AND m.user_id = $3)
       FOR UPDATE OF rd`,
        [envelopeId, deviceId, userId]
      );

      if (rdRes.rows.length === 0 || rdRes.rows[0].recipient_user_id !== userId) {
        throw new ForbiddenException("Delivery acknowledgement unauthorized for envelope");
      }

      const rdRecord = rdRes.rows[0];
      const ackId = generateUUIDv7();

      await client.query(
        `UPDATE message_recipient_devices
         SET delivery_status = CASE WHEN delivery_status = 'read' THEN 'read' ELSE 'delivered' END,
             delivered_at = COALESCE(delivered_at, CURRENT_TIMESTAMP), updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [rdRecord.id]
      );

      await client.query(
        `INSERT INTO message_acknowledgements (id, envelope_id, recipient_device_id, ack_type)
         VALUES ($1, $2, $3, 'delivery')
         ON CONFLICT (envelope_id, recipient_device_id, ack_type) DO NOTHING`,
        [ackId, envelopeId, deviceId]
      );

      await client.query("COMMIT");
      return { status: "delivered", envelopeId, deviceId };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  async acknowledgeRead(userId: string, deviceId: string, envelopeId: string) {
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");
      const target = await client.query(
        `SELECT e.conversation_id, e.server_accepted_at
         FROM message_envelopes e
         JOIN message_recipient_devices rd ON rd.envelope_id = e.id
         JOIN devices d ON d.id = rd.recipient_device_id
         JOIN conversation_members m ON m.conversation_id = e.conversation_id AND m.user_id = $2
         WHERE e.id = $1 AND e.recipient_user_id = $2 AND d.id = $3
           AND d.user_id = $2 AND NOT d.is_revoked AND e.expires_at > CURRENT_TIMESTAMP
         FOR UPDATE OF rd`,
        [envelopeId, userId, deviceId]
      );
      if (target.rows.length === 0) {
        throw new ForbiddenException("Read acknowledgement unauthorized for envelope");
      }
      const conversationId = target.rows[0].conversation_id;
      await client.query(
        `UPDATE message_recipient_devices
         SET delivery_status = 'read', delivered_at = COALESCE(delivered_at, CURRENT_TIMESTAMP),
             read_at = COALESCE(read_at, CURRENT_TIMESTAMP), updated_at = CURRENT_TIMESTAMP
         WHERE envelope_id = $1 AND recipient_device_id = $2`,
        [envelopeId, deviceId]
      );
      await client.query(
        `INSERT INTO message_acknowledgements (id, envelope_id, recipient_device_id, ack_type)
         VALUES ($1, $2, $3, 'read')
         ON CONFLICT (envelope_id, recipient_device_id, ack_type) DO NOTHING`,
        [generateUUIDv7(), envelopeId, deviceId]
      );
      await client.query(
        `INSERT INTO message_read_states (id, conversation_id, user_id, last_read_envelope_id, last_read_at)
         VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
         ON CONFLICT (conversation_id, user_id)
         DO UPDATE SET last_read_envelope_id = EXCLUDED.last_read_envelope_id,
                       last_read_at = EXCLUDED.last_read_at
         WHERE message_read_states.last_read_envelope_id IS NULL OR
           (SELECT (server_accepted_at, id) FROM message_envelopes WHERE id = message_read_states.last_read_envelope_id)
           < (SELECT (server_accepted_at, id) FROM message_envelopes WHERE id = EXCLUDED.last_read_envelope_id)`,
        [generateUUIDv7(), conversationId, userId, envelopeId]
      );
      await client.query("COMMIT");
      return { status: "read", conversationId, lastReadEnvelopeId: envelopeId };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  async getEnvelopeStatus(userId: string, envelopeId: string) {
    const envRes = await this.pool.query(
      "SELECT id, conversation_id, sender_user_id, recipient_user_id, server_accepted_at, expires_at FROM message_envelopes WHERE id = $1",
      [envelopeId]
    );

    if (envRes.rows.length === 0) {
      throw new NotFoundException("Envelope not found");
    }

    const env = envRes.rows[0];
    if (env.sender_user_id !== userId && env.recipient_user_id !== userId) {
      throw new ForbiddenException("Access denied to envelope status");
    }

    const rdRes = await this.pool.query(
      "SELECT recipient_device_id, delivery_status, delivered_at, read_at FROM message_recipient_devices WHERE envelope_id = $1",
      [envelopeId]
    );

    return {
      envelopeId: env.id,
      conversationId: env.conversation_id,
      serverAcceptedAt: env.server_accepted_at,
      expiresAt: env.expires_at,
      recipientDevices: rdRes.rows
    };
  }
}
