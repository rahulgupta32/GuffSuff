import { Module } from "@nestjs/common";
import { RealtimeGateway } from "./realtime.gateway.js";

@Module({
  imports: [],
  controllers: [],
  providers: [RealtimeGateway]
})
export class AppModule {}
