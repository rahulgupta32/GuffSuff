import { createDatabasePool } from "@guffsuff/database";

export async function processOfflineMessageRetries() {
  const pool = createDatabasePool();
  try {
    // Find queued or routed recipient devices with attempts < 5
    const res = await pool.query(`
      SELECT rd.id AS recipient_device_record_id, rd.envelope_id, rd.recipient_device_id, rd.delivery_attempts_count
      FROM message_recipient_devices rd
      JOIN message_envelopes e ON rd.envelope_id = e.id
      WHERE rd.delivery_status IN ('accepted', 'queued', 'routed')
        AND e.expires_at > CURRENT_TIMESTAMP
        AND rd.delivery_attempts_count < 5
      LIMIT 50
    `);

    for (const row of res.rows) {
      await pool.query(`
        UPDATE message_recipient_devices
        SET delivery_status = 'queued',
            delivery_attempts_count = delivery_attempts_count + 1,
            last_attempted_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $1
      `, [row.recipient_device_record_id]);

      // Simulate push wake-up event (contains ONLY opaque metadata)
      console.log(`[WORKER-PUSH-SIMULATOR] Sent opaque wake-up ping to device: ${row.recipient_device_id} for envelope: ${row.envelope_id}`);
    }
  } catch (err) {
    console.error("[WORKER-TRANSPORT-ERROR]", err);
  } finally {
    await pool.end();
  }
}

export async function processExpiredEnvelopeCleanup() {
  const pool = createDatabasePool();
  try {
    const res = await pool.query(`
      UPDATE message_recipient_devices
      SET delivery_status = 'expired', updated_at = CURRENT_TIMESTAMP
      FROM message_envelopes e
      WHERE message_recipient_devices.envelope_id = e.id
        AND e.expires_at <= CURRENT_TIMESTAMP
        AND message_recipient_devices.delivery_status IN ('accepted', 'queued', 'routed')
      RETURNING message_recipient_devices.id
    `);

    if (res.rowCount && res.rowCount > 0) {
      console.log(`[WORKER-EXPIRATION] Expired ${res.rowCount} undelivered message recipient device records`);
    }
  } catch (err) {
    console.error("[WORKER-EXPIRATION-ERROR]", err);
  } finally {
    await pool.end();
  }
}
