import { Controller, Get } from "@nestjs/common";

@Controller()
export class HealthController {
  @Get("health")
  getHealth() {
    return {
      status: "OK",
      service: "api",
      version: "0.1.0-dev",
      timestamp: new Date().toISOString()
    };
  }

  @Get("readiness")
  getReadiness() {
    return {
      ready: true,
      service: "api",
      checks: {
        database: true,
        redis: true
      },
      timestamp: new Date().toISOString()
    };
  }
}
