import { identitySecret } from "./identity-secret.js";
import * as crypto from "crypto";
import jwt from "jsonwebtoken";
import { Pool } from "pg";
import { generateUUIDv7 } from "@guffsuff/id-generation";

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresInSeconds: number;
  sessionId: string;
  familyId: string;
}

export class SessionService {
  private readonly jwtSecret: string;
  private readonly accessTokenTtl = 15 * 60; // 15 minutes
  private readonly refreshTokenTtlDays = 30; // 30 days

  constructor(private readonly pool: Pool) {
    this.jwtSecret = identitySecret(
      "JWT_ACCESS_SECRET",
      "default_guffsuff_jwt_secret_v1_secure_32bytes!!"
    );
  }

  public hashRefreshToken(token: string): string {
    return crypto.createHash("sha256").update(token).digest("hex");
  }

  public generateAccessToken(payload: {
    sessionId: string;
    userId: string;
    deviceId: string;
    sessionVersion: number;
  }): string {
    return jwt.sign(payload, this.jwtSecret, {
      expiresIn: this.accessTokenTtl,
      issuer: "guffsuff-api",
      audience: "guffsuff-client"
    });
  }

  public verifyAccessToken(token: string): {
    sessionId: string;
    userId: string;
    deviceId: string;
    sessionVersion: number;
  } {
    return jwt.verify(token, this.jwtSecret, {
      issuer: "guffsuff-api",
      audience: "guffsuff-client"
    }) as any;
  }

  public async createSession(userId: string, deviceId: string): Promise<TokenPair> {
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");

      const sessionId = generateUUIDv7();
      const familyId = generateUUIDv7();
      const sessionVersion = 1;
      const now = new Date();
      const sessionExpiresAt = new Date(
        now.getTime() + this.refreshTokenTtlDays * 24 * 60 * 60 * 1000
      );

      // 1. Create Session
      await client.query(
        `INSERT INTO sessions (id, user_id, device_id, session_version, created_at, expires_at)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [sessionId, userId, deviceId, sessionVersion, now, sessionExpiresAt]
      );

      // 2. Create Refresh Token Family
      await client.query(
        `INSERT INTO refresh_token_families (id, user_id, device_id, is_compromised, created_at, updated_at, session_id)
         VALUES ($1, $2, $3, false, $4, $4, $5)`,
        [familyId, userId, deviceId, now, sessionId]
      );

      // 3. Issue First Refresh Token Instance
      const rawRefreshToken = generateUUIDv7() + "." + crypto.randomBytes(32).toString("hex");
      const verifierHash = this.hashRefreshToken(rawRefreshToken);
      const tokenInstanceId = generateUUIDv7();
      const refreshExpiresAt = sessionExpiresAt;

      await client.query(
        `INSERT INTO refresh_tokens 
         (id, family_id, token_verifier_hash, parent_token_id, replacement_token_id, expires_at, is_rotated, is_revoked, created_at)
         VALUES ($1, $2, $3, NULL, NULL, $4, false, false, $5)`,
        [tokenInstanceId, familyId, verifierHash, refreshExpiresAt, now]
      );

      await client.query("COMMIT");

      const accessToken = this.generateAccessToken({
        sessionId,
        userId,
        deviceId,
        sessionVersion
      });

      return {
        accessToken,
        refreshToken: rawRefreshToken,
        expiresInSeconds: this.accessTokenTtl,
        sessionId,
        familyId
      };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  public async rotateRefreshToken(rawRefreshToken: string): Promise<TokenPair> {
    const verifierHash = this.hashRefreshToken(rawRefreshToken);
    const client = await this.pool.connect();

    try {
      await client.query("BEGIN");

      // 1. Query token instance & family
      const { rows } = await client.query(
        `SELECT rt.id as token_id, rt.family_id, rt.is_rotated, rt.rotated_at, rt.is_revoked, rt.expires_at, rt.replacement_token_id,
                rf.user_id, rf.device_id, rf.is_compromised, s.id AS session_id, s.session_version,
                s.revoked_at AS session_revoked_at, s.expires_at AS session_expires_at, d.is_revoked AS device_revoked
         FROM refresh_tokens rt
         JOIN refresh_token_families rf ON rt.family_id = rf.id
         JOIN sessions s ON rf.session_id = s.id
         JOIN devices d ON s.device_id = d.id
         WHERE rt.token_verifier_hash = $1
         FOR UPDATE OF rt, rf, s, d`,
        [verifierHash]
      );

      if (rows.length === 0) {
        throw new Error("Invalid or unknown refresh token");
      }

      const tokenRecord = rows[0];

      // 2. Check if family is compromised or token is revoked or expired
      if (
        tokenRecord.is_compromised ||
        tokenRecord.session_revoked_at ||
        tokenRecord.device_revoked ||
        new Date(tokenRecord.session_expires_at).getTime() <= Date.now() ||
        tokenRecord.is_revoked ||
        new Date(tokenRecord.expires_at) < new Date()
      ) {
        throw new Error("Refresh token is invalid or revoked");
      }

      // 3. REUSE DETECTION HANDLING
      if (tokenRecord.is_rotated) {
        // Raw successor tokens are never stored. Reuse fails closed; clients must
        // serialize refresh requests rather than receive an invalid old token.
        // OUTSIDE GRACE WINDOW REUSE DETECTED -> FAMILY COMPROMISE!
        await client.query(
          `UPDATE refresh_token_families SET is_compromised = true, updated_at = NOW() WHERE id = $1`,
          [tokenRecord.family_id]
        );
        await client.query(
          `UPDATE refresh_tokens SET is_revoked = true, revoked_at = NOW() WHERE family_id = $1`,
          [tokenRecord.family_id]
        );
        await client.query(
          `UPDATE sessions SET revoked_at = NOW() WHERE user_id = $1 AND device_id = $2`,
          [tokenRecord.user_id, tokenRecord.device_id]
        );

        // Record High-Severity Security Event
        await client.query(
          `INSERT INTO security_events 
           (id, user_id, device_id, event_type, severity, user_description_key, device_context_json, internal_metadata_json, created_at)
           VALUES ($1, $2, $3, 'refresh_token_reuse_detected', 'high', 'sec_event.refresh_token_reuse', '{}', $4, NOW())`,
          [
            generateUUIDv7(),
            tokenRecord.user_id,
            tokenRecord.device_id,
            JSON.stringify({
              familyId: tokenRecord.family_id,
              attemptedTokenId: tokenRecord.token_id
            })
          ]
        );

        await client.query("COMMIT");
        throw new Error("Security Alert: Refresh token reuse detected. Session terminated.");
      }

      // 4. NORMAL ROTATION
      const newRawRefreshToken = generateUUIDv7() + "." + crypto.randomBytes(32).toString("hex");
      const newVerifierHash = this.hashRefreshToken(newRawRefreshToken);
      const newTokenInstanceId = generateUUIDv7();
      const now = new Date();
      const expiresAt = new Date(tokenRecord.expires_at);

      // Insert replacement token
      await client.query(
        `INSERT INTO refresh_tokens 
         (id, family_id, token_verifier_hash, parent_token_id, replacement_token_id, expires_at, is_rotated, is_revoked, created_at)
         VALUES ($1, $2, $3, $4, NULL, $5, false, false, $6)`,
        [
          newTokenInstanceId,
          tokenRecord.family_id,
          newVerifierHash,
          tokenRecord.token_id,
          expiresAt,
          now
        ]
      );

      // Mark old token as rotated
      await client.query(
        `UPDATE refresh_tokens
         SET is_rotated = true, rotated_at = $1, replacement_token_id = $2
         WHERE id = $3`,
        [now, newTokenInstanceId, tokenRecord.token_id]
      );

      await client.query("COMMIT");

      const accessToken = this.generateAccessToken({
        sessionId: tokenRecord.session_id,
        userId: tokenRecord.user_id,
        deviceId: tokenRecord.device_id,
        sessionVersion: tokenRecord.session_version
      });

      return {
        accessToken,
        refreshToken: newRawRefreshToken,
        expiresInSeconds: this.accessTokenTtl,
        sessionId: tokenRecord.session_id,
        familyId: tokenRecord.family_id
      };
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  public async revokeSession(sessionId: string): Promise<void> {
    await this.pool.query(`UPDATE sessions SET revoked_at = NOW() WHERE id = $1`, [sessionId]);
  }

  public async revokeAllSessionsForUser(userId: string): Promise<void> {
    await this.pool.query(`UPDATE sessions SET revoked_at = NOW() WHERE user_id = $1`, [userId]);
    await this.pool.query(
      `UPDATE refresh_token_families SET is_compromised = true, updated_at = NOW() WHERE user_id = $1`,
      [userId]
    );
    await this.pool.query(
      `UPDATE refresh_tokens SET is_revoked = true, revoked_at = NOW() 
       WHERE family_id IN (SELECT id FROM refresh_token_families WHERE user_id = $1)`,
      [userId]
    );
  }
}
