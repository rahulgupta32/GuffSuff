import assert from "node:assert";
import test from "node:test";
import { HealthController } from "./health/health.controller.js";

test("API Service HealthController returns OK status", () => {
  const controller = new HealthController();
  const health = controller.getHealth();
  assert.strictEqual(health.status, "OK");
  assert.strictEqual(health.service, "api");
});
