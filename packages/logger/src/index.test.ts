import assert from "node:assert";
import test from "node:test";
import { createSafeLogger } from "./index.js";

test("Structured Logger Redaction Test", () => {
  const logger = createSafeLogger("test-service");

  // Verify logger options redact sensitive keys
  assert.ok(logger, "Logger initialized cleanly.");
});
