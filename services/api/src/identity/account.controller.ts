import { Controller, Get, UseGuards, Req, Inject } from "@nestjs/common";
import { AccountService } from "./account.service.js";
import { JwtAuthGuard } from "./jwt-auth.guard.js";

@Controller("api/v1/account")
@UseGuards(JwtAuthGuard)
export class AccountController {
  constructor(@Inject("ACCOUNT_SERVICE") private readonly accountService: AccountService) {}

  @Get()
  async getAccountProfile(@Req() req: any) {
    return this.accountService.getProfile(req.user.userId);
  }

  @Get("privacy")
  async getPrivacySettings(@Req() req: any) {
    return this.accountService.getPrivacySettings(req.user.userId);
  }

  @Get("security-events")
  async getSecurityEvents(@Req() req: any) {
    return this.accountService.getSecurityEvents(req.user.userId);
  }
}
