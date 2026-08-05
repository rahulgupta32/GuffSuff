import * as argon2 from "argon2";
import { Pool } from "pg";
import { generateUUIDv7 } from "@guffsuff/id-generation";

export class RegistrationLockService {
  private readonly pinPepper: string;

  constructor(private readonly pool: Pool) {
    this.pinPepper = process.env.REGISTRATION_LOCK_PEPPER || "default_guffsuff_pin_pepper_v1_32chars!!";
  }

  private getPepperedPin(pin: string): string {
    return `${pin}:${this.pinPepper}`;
  }

  public async hashPin(pin: string): Promise<string> {
    if (!/^\d{6,12}$/.test(pin)) {
      throw new Error("Registration lock PIN must be 6 to 12 digits");
    }
    return argon2.hash(this.getPepperedPin(pin), {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 4
    });
  }

  public async setPin(userId: string, pin: string): Promise<void> {
    const pinHash = await this.hashPin(pin);
    const now = new Date();
    await this.pool.query(
      `INSERT INTO registration_lock_credentials (user_id, pin_argon2_hash, enabled_at, updated_at)
       VALUES ($1, $2, $3, $3)
       ON CONFLICT (user_id) DO UPDATE SET pin_argon2_hash = $2, updated_at = $3`,
      [userId, pinHash, now]
    );

    await this.pool.query(
      `INSERT INTO security_events 
       (id, user_id, device_id, event_type, severity, user_description_key, device_context_json, internal_metadata_json, created_at)
       VALUES ($1, $2, NULL, 'registration_lock_enabled', 'medium', 'sec_event.reg_lock_enabled', '{}', '{}', $3)`,
      [generateUUIDv7(), userId, now]
    );
  }

  public async verifyPin(userId: string, candidatePin: string, ipAddress?: string): Promise<boolean> {
    // 1. Check attempt lockout window (5 failed attempts in last 30 minutes)
    const attemptsRes = await this.pool.query(
      `SELECT is_successful FROM registration_lock_attempts 
       WHERE user_id = $1 AND created_at > NOW() - INTERVAL '30 minutes'
       ORDER BY created_at DESC`,
      [userId]
    );

    const consecutiveFailures = attemptsRes.rows.filter((r: { is_successful: boolean }) => !r.is_successful).length;
    if (consecutiveFailures >= 5) {
      throw new Error("Too many failed registration-lock PIN attempts. Account locked for 30 minutes.");
    }

    // 2. Fetch Credential Hash
    const credRes = await this.pool.query(
      `SELECT pin_argon2_hash FROM registration_lock_credentials WHERE user_id = $1`,
      [userId]
    );
    if (credRes.rows.length === 0) {
      throw new Error("Registration lock PIN is not set for this account");
    }

    const hash = credRes.rows[0].pin_argon2_hash;
    const isMatch = await argon2.verify(hash, this.getPepperedPin(candidatePin));

    // 3. Record Atomic Attempt Record
    await this.pool.query(
      `INSERT INTO registration_lock_attempts (id, user_id, is_successful, ip_address, created_at)
       VALUES ($1, $2, $3, $4, NOW())`,
      [generateUUIDv7(), userId, isMatch, ipAddress || null]
    );

    return isMatch;
  }

  public async disablePin(userId: string, currentPin: string): Promise<void> {
    const isValid = await this.verifyPin(userId, currentPin);
    if (!isValid) {
      throw new Error("Incorrect registration lock PIN");
    }

    await this.pool.query(
      `DELETE FROM registration_lock_credentials WHERE user_id = $1`,
      [userId]
    );

    await this.pool.query(
      `INSERT INTO security_events 
       (id, user_id, device_id, event_type, severity, user_description_key, device_context_json, internal_metadata_json, created_at)
       VALUES ($1, $2, NULL, 'registration_lock_disabled', 'medium', 'sec_event.reg_lock_disabled', '{}', '{}', NOW())`,
      [generateUUIDv7(), userId]
    );
  }
}
