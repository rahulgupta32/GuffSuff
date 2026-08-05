import * as crypto from "crypto";
import { Pool } from "pg";
import { OtpProvider, DevelopmentOtpProvider, ProductionOtpProvider } from "./otp.provider.js";
import { generateUUIDv7 } from "@guffsuff/id-generation";

export class OtpService {
  private readonly pepperV1: string;
  private readonly provider: OtpProvider;

  constructor(private readonly pool: Pool) {
    this.pepperV1 = process.env.OTP_VERIFIER_PEPPER_V1 || "default_guffsuff_otp_pepper_v1_secure_key";
    const env = process.env.NODE_ENV || "development";
    if (env === "production" || env === "staging") {
      this.provider = new ProductionOtpProvider();
    } else {
      this.provider = new DevelopmentOtpProvider();
    }
  }

  public computeVerifierHash(challengeId: string, otpCode: string): string {
    return crypto
      .createHmac("sha256", this.pepperV1)
      .update(`${challengeId}:${otpCode}`)
      .digest("hex");
  }

  public timingSafeVerify(candidateHash: string, expectedHash: string): boolean {
    const candidateBuf = Buffer.from(candidateHash, "hex");
    const expectedBuf = Buffer.from(expectedHash, "hex");
    if (candidateBuf.length !== expectedBuf.length) return false;
    return crypto.timingSafeEqual(candidateBuf, expectedBuf);
  }

  public async requestOtpChallenge(
    phoneBlindIndex: string,
    _ipAddress?: string,
    _installationId?: string
  ): Promise<{ challengeId: string; resendAvailableAt: Date; expiresAt: Date }> {
    // 1. Layered Abuse Controls Check
    const recentChallenges = await this.pool.query(
      `SELECT created_at FROM otp_challenges 
       WHERE phone_blind_index = $1 AND created_at > NOW() - INTERVAL '24 hours'
       ORDER BY created_at DESC`,
      [phoneBlindIndex]
    );

    // Progressive Cooldown: 60s, 120s, 300s
    let cooldownSeconds = 60;
    if (recentChallenges.rows.length === 1) cooldownSeconds = 120;
    else if (recentChallenges.rows.length >= 2) cooldownSeconds = 300;

    if (recentChallenges.rows.length > 0) {
      const lastCreated = new Date(recentChallenges.rows[0].created_at).getTime();
      const now = Date.now();
      if (now - lastCreated < cooldownSeconds * 1000) {
        const secondsRemaining = Math.ceil((cooldownSeconds * 1000 - (now - lastCreated)) / 1000);
        throw new Error(`OTP resend cooldown active. Try again in ${secondsRemaining} seconds.`);
      }
    }

    // 2. Generate 6-digit random code
    const rawOtp = crypto.randomInt(100000, 1000000).toString();
    const challengeId = generateUUIDv7();
    const verifierHash = this.computeVerifierHash(challengeId, rawOtp);

    const now = new Date();
    const expiresAt = new Date(now.getTime() + 5 * 60 * 1000); // 5 minutes
    const resendAvailableAt = new Date(now.getTime() + cooldownSeconds * 1000);

    // 3. Insert Challenge into DB
    await this.pool.query(
      `INSERT INTO otp_challenges 
       (id, phone_blind_index, verifier_hash, attempts_count, max_attempts, expires_at, resend_available_at, is_verified, created_at)
       VALUES ($1, $2, $3, 0, 3, $4, $5, false, $6)`,
      [challengeId, phoneBlindIndex, verifierHash, expiresAt, resendAvailableAt, now]
    );

    // 4. Send via Provider Abstraction
    const deliveryResult = await this.provider.sendOtp(challengeId, phoneBlindIndex, rawOtp);

    // 5. Record Delivery Attempt
    await this.pool.query(
      `INSERT INTO otp_delivery_attempts
       (id, challenge_id, provider_name, provider_request_id, status, cost_amount, cost_currency, error_code, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        generateUUIDv7(),
        challengeId,
        deliveryResult.providerName,
        deliveryResult.providerRequestId || null,
        deliveryResult.success ? "DELIVERED" : "FAILED",
        deliveryResult.costAmount,
        deliveryResult.costCurrency,
        deliveryResult.errorCode || null,
        now
      ]
    );

    return { challengeId, resendAvailableAt, expiresAt };
  }

  public async verifyOtpChallenge(challengeId: string, candidateOtp: string): Promise<boolean> {
    const { rows } = await this.pool.query(
      `SELECT verifier_hash, attempts_count, max_attempts, expires_at, is_verified 
       FROM otp_challenges WHERE id = $1 FOR UPDATE`,
      [challengeId]
    );

    if (rows.length === 0) {
      throw new Error("Invalid or expired OTP challenge");
    }

    const challenge = rows[0];

    if (challenge.is_verified) {
      throw new Error("OTP challenge has already been verified");
    }

    if (new Date(challenge.expires_at) < new Date()) {
      throw new Error("OTP challenge has expired");
    }

    if (challenge.attempts_count >= challenge.max_attempts) {
      throw new Error("Maximum OTP verification attempts exceeded");
    }

    const candidateHash = this.computeVerifierHash(challengeId, candidateOtp);
    const isMatch = this.timingSafeVerify(candidateHash, challenge.verifier_hash);

    if (isMatch) {
      await this.pool.query(
        `UPDATE otp_challenges SET is_verified = true, attempts_count = attempts_count + 1 WHERE id = $1`,
        [challengeId]
      );
      return true;
    } else {
      await this.pool.query(
        `UPDATE otp_challenges SET attempts_count = attempts_count + 1 WHERE id = $1`,
        [challengeId]
      );
      return false;
    }
  }
}
