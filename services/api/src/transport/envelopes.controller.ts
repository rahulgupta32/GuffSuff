import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus
} from "@nestjs/common";
import { JwtAuthGuard } from "../identity/jwt-auth.guard.js";
import { MessageEnvelopeService } from "./message-envelope.service.js";
import { SubmitMessageEnvelopeSchema, AcknowledgeReadSchema } from "@guffsuff/contracts";

@Controller("api/v1")
@UseGuards(JwtAuthGuard)
export class EnvelopesController {
  constructor(private readonly envelopeService: MessageEnvelopeService) {}

  @Post("conversations/:conversationId/envelopes")
  @HttpCode(HttpStatus.CREATED)
  async submitEnvelope(
    @Req() req: any,
    @Param("conversationId") conversationId: string,
    @Body() body: any
  ) {
    const validated = SubmitMessageEnvelopeSchema.parse({
      ...body,
      conversationId
    });
    return this.envelopeService.submitEnvelope(req.user.sub, req.user.deviceId, validated);
  }

  @Get("conversations/:conversationId/envelopes/pending")
  async getPendingEnvelopes(@Req() req: any) {
    return this.envelopeService.getPendingEnvelopes(req.user.sub, req.user.deviceId);
  }

  @Post("envelopes/:envelopeId/delivered")
  @HttpCode(HttpStatus.OK)
  async acknowledgeDelivery(@Req() req: any, @Param("envelopeId") envelopeId: string) {
    return this.envelopeService.acknowledgeDelivery(req.user.sub, req.user.deviceId, envelopeId);
  }

  @Post("envelopes/:envelopeId/read")
  @HttpCode(HttpStatus.OK)
  async acknowledgeRead(
    @Req() req: any,
    @Param("envelopeId") envelopeId: string,
    @Body() body: any
  ) {
    const validated = AcknowledgeReadSchema.parse(body);
    return this.envelopeService.acknowledgeRead(
      req.user.sub,
      validated.lastReadEnvelopeId,
      envelopeId
    );
  }

  @Get("envelopes/:envelopeId/status")
  async getEnvelopeStatus(@Req() req: any, @Param("envelopeId") envelopeId: string) {
    return this.envelopeService.getEnvelopeStatus(req.user.sub, envelopeId);
  }
}
