import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus,
  BadRequestException
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
    return this.envelopeService.submitEnvelope(req.user.userId, req.user.deviceId, validated);
  }

  @Get("conversations/:conversationId/recipients/:recipientUserId/devices")
  listRecipientDevices(
    @Req() req: any,
    @Param("conversationId") conversationId: string,
    @Param("recipientUserId") recipientUserId: string
  ) {
    return this.envelopeService.listRecipientDevices(
      req.user.userId,
      req.user.deviceId,
      conversationId,
      recipientUserId
    );
  }

  @Post("conversations/:conversationId/device-envelopes")
  @HttpCode(HttpStatus.CREATED)
  submitDeviceEnvelopes(
    @Req() req: any,
    @Param("conversationId") conversationId: string,
    @Body() body: any
  ) {
    return this.envelopeService.submitDeviceEnvelopes(req.user.userId, req.user.deviceId, {
      ...body,
      conversationId
    });
  }

  @Get("conversations/:conversationId/envelopes/pending")
  async getPendingEnvelopes(@Req() req: any, @Param("conversationId") conversationId: string) {
    return this.envelopeService.getPendingEnvelopes(
      req.user.userId,
      req.user.deviceId,
      conversationId
    );
  }

  @Post("envelopes/:envelopeId/delivered")
  @HttpCode(HttpStatus.OK)
  async acknowledgeDelivery(@Req() req: any, @Param("envelopeId") envelopeId: string) {
    return this.envelopeService.acknowledgeDelivery(req.user.userId, req.user.deviceId, envelopeId);
  }

  @Post("envelopes/:envelopeId/read")
  @HttpCode(HttpStatus.OK)
  async acknowledgeRead(
    @Req() req: any,
    @Param("envelopeId") envelopeId: string,
    @Body() body: any
  ) {
    const validated = AcknowledgeReadSchema.parse(body);
    if (validated.lastReadEnvelopeId !== envelopeId) {
      throw new BadRequestException("Read receipt must match the envelope in the URL");
    }
    return this.envelopeService.acknowledgeRead(req.user.userId, req.user.deviceId, envelopeId);
  }

  @Get("envelopes/:envelopeId/status")
  async getEnvelopeStatus(@Req() req: any, @Param("envelopeId") envelopeId: string) {
    return this.envelopeService.getEnvelopeStatus(req.user.userId, envelopeId);
  }
}
