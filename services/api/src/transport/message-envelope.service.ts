import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException
} from "@nestjs/common";
import { createDatabasePool } from "@guffsuff/database";
import { generateUUIDv7 } from "@guffsuff/id-generation";
import { SubmitMessageEnvelope } from "@guffsuff/contracts";
import * as crypto from "crypto";

@Injectable()
export class MessageEnvelopeService {
  private pool = createDatabasePool();

  async submitEnvelope(senderUserId: string, senderDeviceId: string, dto: SubmitMessageEnvelope) {
    // 1. Verify sender device is active
    const deviceRes = await this.pool.query(
      "SELECT id, is_revoked FROM devices WHERE id = $1 AND user_id = $2",
      [senderDeviceId, senderUserId]
    );
    if (deviceRes.rows.length === 0 || deviceRes.rows[0].is_revoked) {
      throw new ForbiddenException("Sender device is invalid or revoked");
    }

    // 2. Verify conversation membership
    const memberRes = await this.pool.query(
      "SELECT conversation_id FROM conversation_members WHERE conversation_id = $1 AND user_id = $2",
      [dto.conversationId, senderUserId]
    );
    if (memberRes.rows.length === 0) {
      throw new ForbiddenException("Access denied to conversation");
    }

    // 3. Compute payload digest and check payload length
    const opaqueBuffer = Buffer.from(dto.opaquePayloadBase64, "base64");
    if (opaqueBuffer.length > 65536) {
      throw new BadRequestException("Opaque payload exceeds maximum allowed size of 64KB");
    }

    const payloadDigest = crypto.createHash("sha256").update(opaqueBuffer).digest("hex");

    // 4. Check idempotency key
    const idempRes = await this.pool.query(
      "SELECT envelope_id, payload_digest_sha256 FROM message_idempotency_keys WHERE sender_device_id = $1 AND idempotency_key = $2",
      [senderDeviceId, dto.idempotencyKey]
    );

    if (idempRes.rows.length > 0) {
      const existing = idempRes.rows[0];
      if (existing.payload_digest_sha256 !== payloadDigest) {
        throw new BadRequestException("Idempotency key reused with different payload digest");
      }

      // Return cached envelope response
      const cachedEnv = await this.pool.query(
        "SELECT id, conversation_id, sender_user_id, sender_device_id, recipient_user_id, protocol_version, payload_byte_length, server_accepted_at, expires_at FROM message_envelopes WHERE id = $1",
        [existing.envelope_id]
      );
      return {
        ...cachedEnv.rows[0],
        idempotentRetry: true
      };
    }

    // 5. Resolve active recipient devices
    const recipientDevicesRes = await this.pool.query(
      "SELECT id FROM devices WHERE user_id = $1 AND is_revoked = false",
      [dto.recipientUserId]
    );

    const envelopeId = generateUUIDv7();
    const idempRecordId = generateUUIDv7();

    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");

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

  async getPendingEnvelopes(userId: string, deviceId: string) {
    const res = await this.pool.query(
      `SELECT e.id, e.conversation_id, e.sender_user_id, e.sender_device_id, e.recipient_user_id,
              e.protocol_version, e.payload_byte_length, encode(e.opaque_payload, 'base64') AS opaque_payload_base64,
              e.client_created_at, e.server_accepted_at, e.expires_at, rd.delivery_status
       FROM message_envelopes e
       JOIN message_recipient_devices rd ON e.id = rd.envelope_id
       WHERE rd.recipient_device_id = $1 AND e.recipient_user_id = $2
         AND rd.delivery_status IN ('accepted', 'queued', 'routed')
         AND e.expires_at > CURRENT_TIMESTAMP
       ORDER BY e.server_accepted_at ASC`,
      [deviceId, userId]
    );
    return res.rows;
  }

  async acknowledgeDelivery(userId: string, deviceId: string, envelopeId: string) {
    const rdRes = await this.pool.query(
      `SELECT rd.id, rd.delivery_status, e.recipient_user_id
       FROM message_recipient_devices rd
       JOIN message_envelopes e ON rd.envelope_id = e.id
       WHERE rd.envelope_id = $1 AND rd.recipient_device_id = $2`,
      [envelopeId, deviceId]
    );

    if (rdRes.rows.length === 0 || rdRes.rows[0].recipient_user_id !== userId) {
      throw new ForbiddenException("Delivery acknowledgement unauthorized for envelope");
    }

    const rdRecord = rdRes.rows[0];
    const ackId = generateUUIDv7();

    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");

      await client.query(
        `UPDATE message_recipient_devices
         SET delivery_status = 'delivered', delivered_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [rdRecord.id]
      );

      await client.query(
        `INSERT INTO message_acknowledgements (id, envelope_id, recipient_device_id, ack_type)
         VALUES ($1, $2, $3, 'delivery')`,
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

  async acknowledgeRead(userId: string, conversationId: string, lastReadEnvelopeId: string) {
    const memberRes = await this.pool.query(
      "SELECT conversation_id FROM conversation_members WHERE conversation_id = $1 AND user_id = $2",
      [conversationId, userId]
    );
    if (memberRes.rows.length === 0) {
      throw new ForbiddenException("Access denied to conversation");
    }

    const readStateId = generateUUIDv7();
    await this.pool.query(
      `INSERT INTO message_read_states (id, conversation_id, user_id, last_read_envelope_id, last_read_at)
       VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
       ON CONFLICT (conversation_id, user_id)
       DO UPDATE SET last_read_envelope_id = $4, last_read_at = CURRENT_TIMESTAMP`,
      [readStateId, conversationId, userId, lastReadEnvelopeId]
    );

    return { status: "read", conversationId, lastReadEnvelopeId };
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
