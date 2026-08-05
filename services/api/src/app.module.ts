import { Module } from "@nestjs/common";
import { HealthController } from "./health/health.controller.js";
import { IdentityModule } from "./identity/identity.module.js";

@Module({
  imports: [IdentityModule],
  controllers: [HealthController],
  providers: []
})
export class AppModule {}
