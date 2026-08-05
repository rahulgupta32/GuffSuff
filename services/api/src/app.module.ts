import { Module } from "@nestjs/common";
import { HealthController } from "./health/health.controller.js";
import { IdentityModule } from "./identity/identity.module.js";
import { TransportModule } from "./transport/transport.module.js";

@Module({
  imports: [IdentityModule, TransportModule],
  controllers: [HealthController],
  providers: []
})
export class AppModule {}
