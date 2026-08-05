import { Controller, Post, Get, Body, Param, Req, UseGuards, HttpCode, HttpStatus } from "@nestjs/common";
import { JwtAuthGuard } from "../identity/jwt-auth.guard.js";
import { ConversationService } from "./conversation.service.js";
import { CreateDirectConversationSchema } from "@guffsuff/contracts";

@Controller("api/v1/conversations")
@UseGuards(JwtAuthGuard)
export class ConversationsController {
  constructor(private readonly conversationService: ConversationService) {}

  @Post("direct")
  @HttpCode(HttpStatus.CREATED)
  async createDirectConversation(@Req() req: any, @Body() body: any) {
    const validated = CreateDirectConversationSchema.parse(body);
    return this.conversationService.getOrCreateDirectConversation(req.user.sub, validated.recipientUserId);
  }

  @Get()
  async listConversations(@Req() req: any) {
    return this.conversationService.listConversations(req.user.sub);
  }

  @Get(":conversationId")
  async getConversation(@Req() req: any, @Param("conversationId") conversationId: string) {
    return this.conversationService.getConversationById(req.user.sub, conversationId);
  }
}
