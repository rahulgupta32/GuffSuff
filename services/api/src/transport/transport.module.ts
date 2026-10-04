import { Module } from "@nestjs/common";
import { ConversationService } from "./conversation.service.js";
import { MessageEnvelopeService } from "./message-envelope.service.js";
import { ConversationsController } from "./conversations.controller.js";
import { EnvelopesController } from "./envelopes.controller.js";

import { PrekeyService } from "./prekey.service.js";
import { PrekeysController } from "./prekeys.controller.js";

@Module({
  controllers: [ConversationsController, EnvelopesController, PrekeysController],
  providers: [ConversationService, MessageEnvelopeService, PrekeyService],
  exports: [ConversationService, MessageEnvelopeService]
})
export class TransportModule {}
