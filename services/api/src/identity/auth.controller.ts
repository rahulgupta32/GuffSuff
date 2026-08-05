import { Controller, Post, Body, UseGuards, Req, HttpCode, HttpStatus, Inject } from "@nestjs/common";
import { OtpService } from "./otp.service.js";
import { AccountService } from "./account.service.js";
import { SessionService } from "./session.service.js";
import { PhoneNumberService } from "./phone-number.service.js";
import { JwtAuthGuard } from "./jwt-auth.guard.js";
import {
  OtpRequestSchema,
  OtpVerifySchema,
  RegisterAccountSchema,
  TokenRefreshSchema
} from "@guffsuff/contracts";

@Controller("api/v1/auth")
export class AuthController {
  constructor(
    @Inject("OTP_SERVICE") private readonly otpService: OtpService,
    @Inject("ACCOUNT_SERVICE") private readonly accountService: AccountService,
    @Inject("SESSION_SERVICE") private readonly sessionService: SessionService,
    @Inject("PHONE_NUMBER_SERVICE") private readonly phoneService: PhoneNumberService
  ) {}

  @Post("otp/request")
  @HttpCode(HttpStatus.OK)
  async requestOtp(@Body() body: any) {
    const validated = OtpRequestSchema.parse(body);
    const normalized = this.phoneService.normalizeToE164(validated.phoneNumber);
    const blindIndex = this.phoneService.generateBlindIndex(normalized);
    const result = await this.otpService.requestOtpChallenge(blindIndex);
    return {
      challengeId: result.challengeId,
      resendAvailableAt: result.resendAvailableAt,
      expiresAt: result.expiresAt
    };
  }

  @Post("otp/verify")
  @HttpCode(HttpStatus.OK)
  async verifyOtp(@Body() body: any) {
    const validated = OtpVerifySchema.parse(body);
    const isSuccess = await this.otpService.verifyOtpChallenge(validated.challengeId, validated.otpCode);
    if (!isSuccess) {
      return { success: false, message: "Invalid OTP code" };
    }
    return { success: true, challengeId: validated.challengeId };
  }

  @Post("register")
  @HttpCode(HttpStatus.CREATED)
  async registerAccount(@Body() body: any) {
    const validated = RegisterAccountSchema.parse(body);
    const result = await this.accountService.registerAccount({
      challengeId: validated.challengeId,
      phoneNumber: body.phoneNumber || "+9779800000000",
      displayName: validated.displayName,
      username: validated.username,
      installationId: body.installationId || "inst_default",
      deviceName: body.deviceName || "Mobile Device",
      platform: body.platform || "android",
      appVersion: body.appVersion || "1.0.0",
      osVersion: body.osVersion || "Android 14",
      locale: validated.locale,
      timezone: validated.timezone,
      termsAccepted: validated.termsAccepted,
      privacyAccepted: validated.privacyAccepted
    });
    return result;
  }

  @Post("refresh")
  @HttpCode(HttpStatus.OK)
  async refreshToken(@Body() body: any) {
    const validated = TokenRefreshSchema.parse(body);
    return this.sessionService.rotateRefreshToken(validated.refreshToken);
  }

  @Post("logout")
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async logout(@Req() req: any) {
    await this.sessionService.revokeSession(req.user.sessionId);
    return { success: true };
  }

  @Post("logout-all")
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async logoutAll(@Req() req: any) {
    await this.sessionService.revokeAllSessionsForUser(req.user.userId);
    return { success: true };
  }
}
