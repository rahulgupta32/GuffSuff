import { Module } from "@nestjs/common";
import { ConversationService } from "./conversation.service.js";
import { MessageEnvelopeService } from "./message-envelope.service.js";
import { ConversationsController } from "./conversations.controller.js";
import { EnvelopesController } from "./envelopes.controller.js";

import { IdentityModule } from "../identity/identity.module.js";

@Module({
  imports: [IdentityModule],
  controllers: [ConversationsController, EnvelopesController],
  providers: [ConversationService, MessageEnvelopeService],
  exports: [ConversationService, MessageEnvelopeService]
})
export class TransportModule {}

