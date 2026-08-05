import { Controller, Post, Body, HttpCode, HttpStatus, Inject } from "@nestjs/common";
import { AccountService } from "./account.service.js";
import { CheckUsernameSchema } from "@guffsuff/contracts";

@Controller("api/v1/usernames")
export class UsernamesController {
  constructor(@Inject("ACCOUNT_SERVICE") private readonly accountService: AccountService) {}

  @Post("check")
  @HttpCode(HttpStatus.OK)
  async checkUsername(@Body() body: any) {
    const validated = CheckUsernameSchema.parse(body);
    const available = await this.accountService.isUsernameAvailable(validated.username);
    return { username: validated.username, available };
  }
}
