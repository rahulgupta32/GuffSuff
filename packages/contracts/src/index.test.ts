import assert from "node:assert";
import test from "node:test";
import { HealthResponseSchema } from "./index.js";

test("HealthResponseSchema validates correct health objects", () => {
  const sample = {
    status: "OK",
    service: "api",
    version: "0.1.0-dev",
    timestamp: new Date().toISOString()
  };

  const parsed = HealthResponseSchema.parse(sample);
  assert.strictEqual(parsed.status, "OK");
  assert.strictEqual(parsed.service, "api");
});
