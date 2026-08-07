import {
  Controller,
  Post,
  Delete,
  Body,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
  Inject
} from "@nestjs/common";
import { RegistrationLockService } from "./registration-lock.service.js";
import { JwtAuthGuard } from "./jwt-auth.guard.js";
import { SetRegistrationLockPinSchema, VerifyRegistrationLockPinSchema } from "@guffsuff/contracts";

@Controller("api/v1/registration-lock")
@UseGuards(JwtAuthGuard)
export class RegistrationLockController {
  constructor(
    @Inject("REGISTRATION_LOCK_SERVICE")
    private readonly regLockService: RegistrationLockService
  ) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  async setPin(@Req() req: any, @Body() body: any) {
    const validated = SetRegistrationLockPinSchema.parse(body);
    await this.regLockService.setPin(req.user.userId, validated.pin);
    return { success: true };
  }

  @Post("verify")
  @HttpCode(HttpStatus.OK)
  async verifyPin(@Req() req: any, @Body() body: any) {
    const validated = VerifyRegistrationLockPinSchema.parse(body);
    const isMatch = await this.regLockService.verifyPin(req.user.userId, validated.pin, req.ip);
    return { verified: isMatch };
  }

  @Delete()
  @HttpCode(HttpStatus.OK)
  async disablePin(@Req() req: any, @Body() body: any) {
    const validated = VerifyRegistrationLockPinSchema.parse(body);
    await this.regLockService.disablePin(req.user.userId, validated.pin);
    return { success: true };
  }
}
