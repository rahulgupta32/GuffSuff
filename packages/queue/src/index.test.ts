import assert from "node:assert";
import test from "node:test";
import { getEnvironmentKeyPrefix } from "./index.js";

test("Queue generates environment-isolated Redis key prefixes", () => {
  assert.strictEqual(getEnvironmentKeyPrefix("production"), "guffsuff:production:");
  assert.strictEqual(getEnvironmentKeyPrefix("staging"), "guffsuff:staging:");
  assert.strictEqual(getEnvironmentKeyPrefix("development"), "guffsuff:development:");
});
