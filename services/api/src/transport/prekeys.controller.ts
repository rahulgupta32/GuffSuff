import { Controller, Post, Body, Param, Req, UseGuards, HttpCode } from "@nestjs/common";
import { JwtAuthGuard } from "../identity/jwt-auth.guard.js";
import { PrekeyService } from "./prekey.service.js";

@Controller("api/v1")
@UseGuards(JwtAuthGuard)
export class PrekeysController {
  constructor(private readonly prekeys: PrekeyService) {}

  @Post("devices/current/prekeys")
  @HttpCode(200)
  publish(@Req() req: any, @Body() body: any) {
    return this.prekeys.publish(req.user.userId, req.user.deviceId, body);
  }

  @Post("conversations/:conversationId/devices/:deviceId/prekey-claims")
  @HttpCode(200)
  claim(
    @Req() req: any,
    @Param("conversationId") conversationId: string,
    @Param("deviceId") deviceId: string,
    @Body() body: any
  ) {
    return this.prekeys.claim(
      req.user.userId,
      req.user.deviceId,
      conversationId,
      deviceId,
      body?.claimId
    );
  }
}
