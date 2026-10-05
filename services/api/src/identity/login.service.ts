import { Pool } from "pg";
import * as argon2 from "argon2";
import { ForbiddenException, UnauthorizedException, HttpException } from "@nestjs/common";
import { LoginAccount } from "@guffsuff/contracts";
import { generateUUIDv7 } from "@guffsuff/id-generation";
import { PhoneNumberService } from "./phone-number.service.js";
import { SessionService } from "./session.service.js";
import { identitySecret } from "./identity-secret.js";

export class LoginService {
  private readonly phones = new PhoneNumberService();
  private readonly pinPepper = identitySecret(
    "REGISTRATION_LOCK_PEPPER",
    "default_guffsuff_pin_pepper_v1_32chars!!"
  );
  constructor(
    private readonly pool: Pool,
    private readonly sessions: SessionService
  ) {}
  async login(input: LoginAccount) {
    const client = await this.pool.connect();
    let committed = false;
    try {
      await client.query("BEGIN");
      const { rows } = await client.query(
        `SELECT phone_blind_index, is_verified, expires_at, consumed_at FROM otp_challenges WHERE id = $1 FOR UPDATE`,
        [input.challengeId]
      );
      const challenge = rows[0];
      const phone = this.phones.normalizeToE164(input.phoneNumber);
      if (
        !challenge ||
        !challenge.is_verified ||
        challenge.consumed_at ||
        new Date(challenge.expires_at).getTime() <= Date.now() ||
        challenge.phone_blind_index !== this.phones.generateBlindIndex(phone)
      ) {
        throw new UnauthorizedException("Invalid verification challenge");
      }
      const account = await client.query(
        `SELECT u.id, u.account_state FROM users u JOIN phone_identities p ON p.user_id = u.id
         WHERE p.phone_blind_index = $1 AND p.verified_at IS NOT NULL FOR UPDATE OF u`,
        [challenge.phone_blind_index]
      );
      const user = account.rows[0];
      if (!user) {
        await client.query("COMMIT");
        committed = true;
        return { registrationRequired: true };
      }
      if (!["active", "pending_profile"].includes(user.account_state)) {
        throw new ForbiddenException("Account unavailable");
      }
      const credentials = await client.query(
        `SELECT pin_argon2_hash FROM registration_lock_credentials WHERE user_id = $1`,
        [user.id]
      );
      if (credentials.rows.length) {
        if (!input.registrationLockPin)
          throw new UnauthorizedException({
            errorCode: "PIN_REQUIRED",
            message: "Registration PIN required"
          });
        const attempts = await client.query(
          `SELECT COUNT(*)::int AS failures FROM registration_lock_attempts WHERE user_id = $1
           AND is_successful = false AND created_at > NOW() - INTERVAL '30 minutes'`,
          [user.id]
        );
        if (attempts.rows[0].failures >= 5)
          throw new HttpException("Please wait before retrying your PIN", 429);
        const matches = await argon2.verify(
          credentials.rows[0].pin_argon2_hash,
          `${input.registrationLockPin}:${this.pinPepper}`
        );
        await client.query(
          `INSERT INTO registration_lock_attempts (id, user_id, is_successful, created_at) VALUES ($1, $2, $3, NOW())`,
          [generateUUIDv7(), user.id, matches]
        );
        if (!matches) {
          await client.query("COMMIT");
          committed = true;
          throw new UnauthorizedException({
            errorCode: "PIN_INVALID",
            message: "Incorrect registration PIN"
          });
        }
      }
      const devices = await client.query(
        `SELECT id, is_revoked FROM devices WHERE user_id = $1 AND installation_id = $2 ORDER BY created_at DESC LIMIT 1 FOR UPDATE`,
        [user.id, input.installationId]
      );
      if (devices.rows[0]?.is_revoked) throw new ForbiddenException("Device revoked");
      const deviceId = devices.rows[0]?.id ?? generateUUIDv7();
      if (!devices.rows.length) {
        await client.query(
          `INSERT INTO devices (id, user_id, installation_id, device_name, platform, app_version, os_version)
          VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            deviceId,
            user.id,
            input.installationId,
            input.deviceName,
            input.platform,
            input.appVersion,
            input.osVersion
          ]
        );
      } else {
        await client.query(`UPDATE devices SET last_seen_at = NOW() WHERE id = $1`, [deviceId]);
      }
      const tokens = await this.sessions.createSession(user.id, deviceId, client);
      await client.query(`UPDATE otp_challenges SET consumed_at = NOW() WHERE id = $1`, [
        input.challengeId
      ]);
      await client.query(
        `INSERT INTO security_events (id, user_id, device_id, event_type, severity, user_description_key)
        VALUES ($1, $2, $3, 'account_login', 'low', 'sec_event.login')`,
        [generateUUIDv7(), user.id, deviceId]
      );
      await client.query("COMMIT");
      committed = true;
      return { registrationRequired: false, userId: user.id, deviceId, ...tokens };
    } catch (error) {
      if (!committed) await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }
}
