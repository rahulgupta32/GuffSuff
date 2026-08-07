import { Pool } from "pg";
import { PhoneNumberService } from "./phone-number.service.js";
import { SessionService } from "./session.service.js";
import { generateUUIDv7 } from "@guffsuff/id-generation";

export class AccountService {
  private readonly phoneService: PhoneNumberService;

  constructor(
    private readonly pool: Pool,
    private readonly sessionService: SessionService
  ) {
    this.phoneService = new PhoneNumberService();
  }

  public async registerAccount(params: {
    challengeId: string;
    phoneNumber: string;
    displayName: string;
    username: string;
    installationId: string;
    deviceName: string;
    platform: "android" | "ios" | "web" | "desktop";
    appVersion: string;
    osVersion: string;
    locale?: string;
    timezone?: string;
    termsAccepted: boolean;
    privacyAccepted: boolean;
  }) {
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");

      // 1. Verify OTP Challenge is marked as verified
      const challengeRes = await client.query(
        `SELECT phone_blind_index, is_verified FROM otp_challenges WHERE id = $1 FOR UPDATE`,
        [params.challengeId]
      );
      if (challengeRes.rows.length === 0 || !challengeRes.rows[0].is_verified) {
        throw new Error("Invalid or unverified OTP challenge");
      }

      const phoneBlindIndex = challengeRes.rows[0].phone_blind_index;
      const normalizedE164 = this.phoneService.normalizeToE164(params.phoneNumber);
      const encryptedPhone = this.phoneService.encryptPhoneNumber(normalizedE164);

      // Check if phone number already belongs to an active account
      const existingPhone = await client.query(
        `SELECT user_id FROM phone_identities WHERE phone_blind_index = $1 AND verified_at IS NOT NULL`,
        [phoneBlindIndex]
      );
      if (existingPhone.rows.length > 0) {
        throw new Error("Phone number is already registered to an existing account");
      }

      // Check username canonical uniqueness
      const canonicalUsername = params.username.toLowerCase();
      const existingUsername = await client.query(
        `SELECT id FROM usernames WHERE username_canonical = $1`,
        [canonicalUsername]
      );
      if (existingUsername.rows.length > 0) {
        throw new Error("Username is already taken");
      }

      // 2. Create User Record
      const userId = generateUUIDv7();
      const now = new Date();
      await client.query(
        `INSERT INTO users (id, account_state, terms_accepted_at, privacy_accepted_at, locale, timezone, created_at, updated_at)
         VALUES ($1, 'active', $2, $3, $4, $5, $6, $6)`,
        [userId, now, now, params.locale || "ne", params.timezone || "Asia/Kathmandu", now]
      );

      // 3. Create Phone Identity
      const phoneId = generateUUIDv7();
      await client.query(
        `INSERT INTO phone_identities (id, user_id, phone_encrypted, phone_blind_index, is_primary, verified_at, created_at, updated_at)
         VALUES ($1, $2, $3, $4, true, $5, $5, $5)`,
        [phoneId, userId, encryptedPhone, phoneBlindIndex, now]
      );

      // 4. Create Profile
      await client.query(
        `INSERT INTO user_profiles (user_id, display_name, avatar_object_key, bio, profile_visibility, created_at, updated_at)
         VALUES ($1, $2, NULL, NULL, 'contacts_only', $3, $3)`,
        [userId, params.displayName, now]
      );

      // 5. Assign Username
      const usernameId = generateUUIDv7();
      await client.query(
        `INSERT INTO usernames (id, user_id, username_canonical, username_display, assigned_at, cooldown_until)
         VALUES ($1, $2, $3, $4, $5, $5)`,
        [usernameId, userId, canonicalUsername, params.username, now]
      );

      // 6. Register Initial Device
      const deviceId = generateUUIDv7();
      await client.query(
        `INSERT INTO devices (id, user_id, installation_id, device_name, platform, app_version, os_version, notification_token_status, is_revoked, created_at, last_seen_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'disabled', false, $8, $8)`,
        [
          deviceId,
          userId,
          params.installationId,
          params.deviceName,
          params.platform,
          params.appVersion,
          params.osVersion,
          now
        ]
      );

      // 7. Initialize Privacy Settings (Defaults)
      await client.query(
        `INSERT INTO privacy_settings (user_id, last_seen_visibility, online_status_visibility, profile_photo_visibility, phone_number_visibility, read_receipts, phone_discoverability, security_notifications, notification_previews, updated_at)
         VALUES ($1, 'contacts_only', 'contacts_only', 'contacts_only', 'nobody', true, false, true, true, $2)`,
        [userId, now]
      );

      // 8. Create Security Event
      await client.query(
        `INSERT INTO security_events (id, user_id, device_id, event_type, severity, user_description_key, device_context_json, internal_metadata_json, created_at)
         VALUES ($1, $2, $3, 'account_registered', 'low', 'sec_event.registration_complete', $4, '{}', $5)`,
        [
          generateUUIDv7(),
          userId,
          deviceId,
          JSON.stringify({ deviceName: params.deviceName, platform: params.platform }),
          now
        ]
      );

      // 9. Create Audit Event
      await client.query(
        `INSERT INTO audit_events 
         (id, actor_type, actor_id, action, target_type, target_id, reason, correlation_id, request_id, outcome, before_state_json, after_state_json, created_at)
         VALUES ($1, 'user', $2, 'account_registered', 'user', $2, 'Registration completed', $3, $3, 'success', NULL, $4, $5)`,
        [
          generateUUIDv7(),
          userId,
          generateUUIDv7(),
          JSON.stringify({ userId, username: canonicalUsername }),
          now
        ]
      );

      await client.query("COMMIT");

      // 10. Issue Tokens
      const tokenPair = await this.sessionService.createSession(userId, deviceId);

      return {
        userId,
        username: canonicalUsername,
        displayName: params.displayName,
        deviceId,
        ...tokenPair
      };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  public async isUsernameAvailable(username: string): Promise<boolean> {
    const canonical = username.toLowerCase();
    const { rows } = await this.pool.query(
      `SELECT id FROM usernames WHERE username_canonical = $1`,
      [canonical]
    );
    return rows.length === 0;
  }

  public async getProfile(userId: string) {
    const { rows } = await this.pool.query(
      `SELECT u.id as user_id, u.account_state, u.locale, u.timezone,
              up.display_name, up.avatar_object_key, up.bio, up.profile_visibility,
              un.username_canonical, un.username_display
       FROM users u
       JOIN user_profiles up ON u.id = up.user_id
       LEFT JOIN usernames un ON u.id = un.user_id
       WHERE u.id = $1`,
      [userId]
    );
    if (rows.length === 0) throw new Error("User profile not found");
    return rows[0];
  }

  public async getPrivacySettings(userId: string) {
    const { rows } = await this.pool.query(
      `SELECT last_seen_visibility, online_status_visibility, profile_photo_visibility, phone_number_visibility, read_receipts, phone_discoverability, security_notifications, notification_previews
       FROM privacy_settings WHERE user_id = $1`,
      [userId]
    );
    if (rows.length === 0) throw new Error("Privacy settings not found");
    return rows[0];
  }

  public async getSecurityEvents(userId: string) {
    // SECURITY CONSTRAINT: Do NOT select internal_metadata_json for user API response
    const { rows } = await this.pool.query(
      `SELECT id, event_type, severity, user_description_key, device_context_json, is_read, created_at
       FROM security_events WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50`,
      [userId]
    );
    return rows;
  }
}
