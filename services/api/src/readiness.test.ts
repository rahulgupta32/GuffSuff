import assert from "node:assert";
import test from "node:test";
import { HealthController } from "./health/health.controller.js";

test("API Liveness endpoint always succeeds independently of external dependencies", () => {
  const controller = new HealthController();
  const health = controller.getHealth();
  assert.strictEqual(health.status, "OK");
  assert.strictEqual(health.service, "api");
});

test("API Readiness probe fails closed (503) when database or redis is unavailable", async () => {
  const controller = new HealthController();

  // Under un-mocked dev environment without running DB/Redis container, getReadiness throws 503 Service Unavailable
  try {
    await controller.getReadiness();
    assert.fail("Should have thrown 503 Service Unavailable");
  } catch (err: any) {
    assert.strictEqual(
      err.status,
      503,
      "Readiness returns 503 Service Unavailable when DB is down"
    );
    const response = err.getResponse();
    assert.strictEqual(response.status, "NOT_READY");
    assert.ok(response.dependencies, "Response contains dependency status summary");
    // Verify zero database passwords or credentials leaked in response
    const jsonStr = JSON.stringify(response);
    assert.strictEqual(
      jsonStr.includes("guffsuff_local_pass"),
      false,
      "Zero secrets leaked in readiness error body"
    );
  }
});
