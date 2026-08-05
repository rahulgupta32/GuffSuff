import { Injectable, CanActivate, ExecutionContext, UnauthorizedException, Inject } from "@nestjs/common";
import { SessionService } from "./session.service.js";
import { Pool } from "pg";

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    @Inject("SESSION_SERVICE") private readonly sessionService: SessionService,
    @Inject("DATABASE_POOL") private readonly pool: Pool
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers["authorization"];
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw new UnauthorizedException("Missing or invalid Authorization header");
    }

    const token = authHeader.split(" ")[1];
    try {
      const payload = this.sessionService.verifyAccessToken(token);

      // Authoritative Session & Device Validation in DB
      const { rows } = await this.pool.query(
        `SELECT s.id as session_id, s.revoked_at as session_revoked, s.session_version,
                d.is_revoked as device_revoked, u.account_state
         FROM sessions s
         JOIN devices d ON s.device_id = d.id
         JOIN users u ON s.user_id = u.id
         WHERE s.id = $1 AND s.user_id = $2 AND s.device_id = $3`,
        [payload.sessionId, payload.userId, payload.deviceId]
      );

      if (rows.length === 0) {
        throw new UnauthorizedException("Session not found");
      }

      const session = rows[0];
      if (session.session_revoked || session.device_revoked) {
        throw new UnauthorizedException("Session or device has been revoked");
      }
      if (session.account_state !== "active" && session.account_state !== "pending_profile") {
        throw new UnauthorizedException("Account is restricted or suspended");
      }
      if (session.session_version !== payload.sessionVersion) {
        throw new UnauthorizedException("Session version mismatch");
      }

      request.user = {
        userId: payload.userId,
        deviceId: payload.deviceId,
        sessionId: payload.sessionId
      };
      return true;
    } catch (err: any) {
      throw new UnauthorizedException(err.message || "Invalid token");
    }
  }
}
