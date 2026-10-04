import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  ConflictException,
  NotFoundException
} from "@nestjs/common";
import { createDatabasePool } from "@guffsuff/database";

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function identifier(value: unknown): asserts value is string {
  if (typeof value !== "string" || !uuid.test(value))
    throw new BadRequestException("Invalid identifier");
}
function keyId(value: unknown): asserts value is number {
  if (!Number.isInteger(value) || (value as number) < 0 || (value as number) > 2147483647)
    throw new BadRequestException("Invalid prekey ID");
}
function publicBytes(value: unknown, length: number) {
  if (typeof value !== "string" || value.length > 128)
    throw new BadRequestException("Invalid public key encoding");
  const bytes = Buffer.from(value, "base64");
  if (
    bytes.length !== length ||
    bytes.toString("base64") !== value ||
    (length === 33 && bytes[0] !== 5)
  )
    throw new BadRequestException("Invalid public key encoding");
  return bytes;
}

@Injectable()
export class PrekeyService {
  private pool = createDatabasePool();

  // Initial bundle is immutable. Rotation is deliberately not implemented by replacing keys silently.
  async publish(userId: string, deviceId: string, body: any) {
    identifier(userId);
    identifier(deviceId);
    if (
      !body ||
      body.protocolVersion !== 1 ||
      !Number.isInteger(body.registrationId) ||
      body.registrationId < 1 ||
      body.registrationId > 16380
    )
      throw new BadRequestException("Invalid bundle metadata");
    keyId(body.signedPrekeyId);
    const identity = publicBytes(body.identityPublicKeyBase64, 33);
    const signed = publicBytes(body.signedPrekeyPublicBase64, 33);
    const signature = publicBytes(body.signedPrekeySignatureBase64, 64);
    const expires = Date.parse(body.expiresAt);
    if (!Number.isFinite(expires) || expires <= Date.now() || expires > Date.now() + 30 * 86400000)
      throw new BadRequestException("Bundle expiry must be within 30 days");
    if (!Array.isArray(body.oneTimePrekeys) || body.oneTimePrekeys.length > 100)
      throw new BadRequestException("Publish at most 100 prekeys");
    const keys = body.oneTimePrekeys.map((key: any) => {
      keyId(key?.keyId);
      return { id: key.keyId, bytes: publicBytes(key.publicKeyBase64, 33) };
    });
    if (new Set(keys.map((key: { id: number }) => key.id)).size !== keys.length)
      throw new BadRequestException("Duplicate prekey IDs");
    if (
      new Set(keys.map((key: { bytes: Buffer }) => key.bytes.toString("base64"))).size !==
      keys.length
    ) {
      throw new BadRequestException("One-time prekeys must use distinct public keys");
    }
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");
      // Always lock the publishing device first, serializing replenishment and revocation.
      const device = await client.query(
        `SELECT d.id FROM devices d JOIN users u ON u.id = d.user_id WHERE d.id = $1 AND d.user_id = $2 AND d.is_revoked = false AND u.account_state = 'active' FOR UPDATE OF d FOR SHARE OF u`,
        [deviceId, userId]
      );
      if (!device.rows.length) throw new ForbiddenException("Active device required");
      const existing = (
        await client.query("SELECT * FROM device_key_bundles WHERE device_id = $1", [deviceId])
      ).rows[0];
      if (existing) {
        if (
          existing.registration_id !== body.registrationId ||
          existing.signed_prekey_id !== body.signedPrekeyId ||
          !existing.identity_key.equals(identity) ||
          !existing.signed_prekey.equals(signed) ||
          !existing.signed_prekey_signature.equals(signature) ||
          new Date(existing.expires_at).getTime() !== expires
        )
          throw new ConflictException(
            "Existing bundle cannot be replaced; identity rotation requires a separate verified flow"
          );
      } else {
        await client.query(
          `INSERT INTO device_key_bundles(device_id, protocol_version, registration_id, identity_key, signed_prekey_id, signed_prekey, signed_prekey_signature, expires_at) VALUES ($1, 1, $2, $3, $4, $5, $6, $7)`,
          [
            deviceId,
            body.registrationId,
            identity,
            body.signedPrekeyId,
            signed,
            signature,
            new Date(expires)
          ]
        );
      }
      for (const key of keys) {
        const old = (
          await client.query(
            "SELECT key_id, public_key FROM device_one_time_prekeys WHERE device_id = $1 AND (key_id = $2 OR public_key = $3)",
            [deviceId, key.id, key.bytes]
          )
        ).rows[0];
        if (old && (old.key_id !== key.id || !old.public_key.equals(key.bytes)))
          throw new ConflictException("Prekey ID cannot be rebound");
        await client.query(
          "INSERT INTO device_one_time_prekeys(device_id, key_id, public_key) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING",
          [deviceId, key.id, key.bytes]
        );
      }
      const count = (
        await client.query(
          "SELECT COUNT(*)::int AS count FROM device_one_time_prekeys WHERE device_id = $1 AND claim_id IS NULL",
          [deviceId]
        )
      ).rows[0].count;
      if (count > 1000) throw new BadRequestException("Available prekey capacity exceeded");
      await client.query("COMMIT");
      return { deviceId, availablePrekeys: count };
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  async claim(
    userId: string,
    requesterDeviceId: string,
    conversationId: string,
    targetDeviceId: string,
    claimId: string
  ) {
    for (const value of [userId, requesterDeviceId, conversationId, targetDeviceId, claimId])
      identifier(value);
    userId = userId.toLowerCase();
    requesterDeviceId = requesterDeviceId.toLowerCase();
    conversationId = conversationId.toLowerCase();
    targetDeviceId = targetDeviceId.toLowerCase();
    claimId = claimId.toLowerCase();
    if (requesterDeviceId === targetDeviceId)
      throw new BadRequestException("Cannot claim own device prekey");
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");
      // Stable device lock order prevents crossed claims from deadlocking.
      const devices = await client.query(
        `SELECT d.id, d.user_id FROM devices d JOIN users u ON u.id = d.user_id
        WHERE d.id = ANY($1::uuid[]) AND d.is_revoked = false AND u.account_state = 'active'
        ORDER BY d.id FOR SHARE OF d, u`,
        [[requesterDeviceId, targetDeviceId]]
      );
      if (
        devices.rows.length !== 2 ||
        !devices.rows.some((d) => d.id === requesterDeviceId && d.user_id === userId)
      )
        throw new ForbiddenException("Active device required");
      const targetUserId = devices.rows.find((d) => d.id === targetDeviceId)!.user_id;
      if (targetUserId === userId)
        throw new BadRequestException("Recipient must be another account");
      const members = await client.query(
        `SELECT user_id FROM conversation_members WHERE conversation_id = $1 AND user_id = ANY($2::uuid[]) FOR SHARE`,
        [conversationId, [userId, targetUserId]]
      );
      if (members.rows.length !== 2)
        throw new ForbiddenException("Both accounts must belong to the conversation");
      // Bundle row lock serializes all claims for one target, including identical HTTP retries.
      const bundle = (
        await client.query(
          "SELECT * FROM device_key_bundles WHERE device_id = $1 AND expires_at > NOW() FOR UPDATE",
          [targetDeviceId]
        )
      ).rows[0];
      if (!bundle) throw new NotFoundException("Unexpired recipient bundle unavailable");
      let key = (
        await client.query(
          "SELECT key_id, public_key FROM device_one_time_prekeys WHERE device_id = $1 AND claimed_by_device_id = $2 AND claim_id = $3",
          [targetDeviceId, requesterDeviceId, claimId]
        )
      ).rows[0];
      if (!key) {
        key = (
          await client.query(
            `UPDATE device_one_time_prekeys SET claimed_by_device_id = $2, claim_id = $3, claimed_at = NOW()
          WHERE device_id = $1 AND key_id = (SELECT key_id FROM device_one_time_prekeys WHERE device_id = $1 AND claim_id IS NULL ORDER BY key_id LIMIT 1)
          RETURNING key_id, public_key`,
            [targetDeviceId, requesterDeviceId, claimId]
          )
        ).rows[0];
      }
      if (!key) throw new ConflictException("Recipient one-time prekeys exhausted");
      await client.query("COMMIT");
      return {
        deviceId: targetDeviceId,
        protocolVersion: bundle.protocol_version,
        registrationId: bundle.registration_id,
        identityPublicKeyBase64: bundle.identity_key.toString("base64"),
        signedPrekeyId: bundle.signed_prekey_id,
        signedPrekeyPublicBase64: bundle.signed_prekey.toString("base64"),
        signedPrekeySignatureBase64: bundle.signed_prekey_signature.toString("base64"),
        expiresAt: new Date(bundle.expires_at).toISOString(),
        oneTimePrekeyId: key.key_id,
        oneTimePrekeyPublicBase64: key.public_key.toString("base64")
      };
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }
}
