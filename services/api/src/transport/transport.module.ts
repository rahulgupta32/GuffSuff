import { Module } from "@nestjs/common";
import { ConversationService } from "./conversation.service.js";
import { MessageEnvelopeService } from "./message-envelope.service.js";
import { ConversationsController } from "./conversations.controller.js";
import { EnvelopesController } from "./envelopes.controller.js";

@Module({
  controllers: [ConversationsController, EnvelopesController],
  providers: [ConversationService, MessageEnvelopeService],
  exports: [ConversationService, MessageEnvelopeService]
})
export class TransportModule {}
