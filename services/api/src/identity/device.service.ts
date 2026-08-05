import { Pool } from "pg";
import { generateUUIDv7 } from "@guffsuff/id-generation";

export class DeviceService {
  constructor(private readonly pool: Pool) {}

  public async listDevices(userId: string, currentDeviceId?: string) {
    const { rows } = await this.pool.query(
      `SELECT id, installation_id, device_name, platform, app_version, os_version,
              notification_token_status, is_revoked, revoked_at, revoked_reason, created_at, last_seen_at
       FROM devices WHERE user_id = $1 AND is_revoked = false
       ORDER BY last_seen_at DESC`,
      [userId]
    );

    return rows.map((d) => ({
      ...d,
      isCurrentDevice: currentDeviceId ? d.id === currentDeviceId : false
    }));
  }

  public async renameDevice(userId: string, deviceId: string, newDeviceName: string) {
    const { rows } = await this.pool.query(
      `UPDATE devices SET device_name = $1, last_seen_at = NOW()
       WHERE id = $2 AND user_id = $3 AND is_revoked = false
       RETURNING id, device_name`,
      [newDeviceName, deviceId, userId]
    );
    if (rows.length === 0) {
      throw new Error("Device not found or already revoked");
    }

    await this.pool.query(
      `INSERT INTO audit_events 
       (id, actor_type, actor_id, action, target_type, target_id, reason, correlation_id, request_id, outcome, before_state_json, after_state_json, created_at)
       VALUES ($1, 'user', $2, 'device_renamed', 'device', $3, 'Device renamed', $4, $4, 'success', NULL, $5, NOW())`,
      [
        generateUUIDv7(),
        userId,
        deviceId,
        generateUUIDv7(),
        JSON.stringify({ deviceId, newDeviceName })
      ]
    );

    return rows[0];
  }

  public async revokeDevice(userId: string, deviceIdToRevoke: string, reason = "user_requested") {
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");

      // 1. Mark Device Revoked
      const deviceRes = await client.query(
        `UPDATE devices 
         SET is_revoked = true, revoked_at = NOW(), revoked_reason = $1 
         WHERE id = $2 AND user_id = $3 AND is_revoked = false
         RETURNING id, device_name`,
        [reason, deviceIdToRevoke, userId]
      );

      if (deviceRes.rows.length === 0) {
        throw new Error("Device not found or already revoked");
      }

      // 2. Revoke Sessions & Refresh Token Families for this device
      await client.query(
        `UPDATE sessions SET revoked_at = NOW() WHERE device_id = $1`,
        [deviceIdToRevoke]
      );
      await client.query(
        `UPDATE refresh_token_families SET is_compromised = true, updated_at = NOW() WHERE device_id = $1`,
        [deviceIdToRevoke]
      );
      await client.query(
        `UPDATE refresh_tokens SET is_revoked = true, revoked_at = NOW() 
         WHERE family_id IN (SELECT id FROM refresh_token_families WHERE device_id = $1)`,
        [deviceIdToRevoke]
      );

      // 3. Create Security Event
      await client.query(
        `INSERT INTO security_events 
         (id, user_id, device_id, event_type, severity, user_description_key, device_context_json, internal_metadata_json, created_at)
         VALUES ($1, $2, $3, 'device_revoked', 'medium', 'sec_event.device_revoked', $4, '{}', NOW())`,
        [
          generateUUIDv7(),
          userId,
          deviceIdToRevoke,
          JSON.stringify({ deviceName: deviceRes.rows[0].device_name, reason })
        ]
      );

      // 4. Create Audit Event
      await client.query(
        `INSERT INTO audit_events 
         (id, actor_type, actor_id, action, target_type, target_id, reason, correlation_id, request_id, outcome, before_state_json, after_state_json, created_at)
         VALUES ($1, 'user', $2, 'device_revoked', 'device', $3, $4, $5, $5, 'success', NULL, $6, NOW())`,
        [
          generateUUIDv7(),
          userId,
          deviceIdToRevoke,
          reason,
          generateUUIDv7(),
          JSON.stringify({ deviceId: deviceIdToRevoke, reason })
        ]
      );

      await client.query("COMMIT");
      return { success: true, revokedDeviceId: deviceIdToRevoke };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }
}
