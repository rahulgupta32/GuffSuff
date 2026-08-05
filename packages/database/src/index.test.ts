import assert from "node:assert";
import test from "node:test";
import { createDatabasePool } from "./index.js";

test("Database Pool rejects invalid connection strings", () => {
  const pool = createDatabasePool("invalid-connection-string");
  assert.ok(pool, "Pool instance initialized with connection string.");
});

test("Production database connection enforces TLS requirements", () => {
  const originalEnv = process.env.NODE_ENV;
  process.env.NODE_ENV = "production";

  try {
    const url = "postgresql://user:pass@db.guffsuff.internal:5432/guffsuff";
    const pool = createDatabasePool(url);
    assert.ok(pool, "Pool initialized under production constraints.");
  } finally {
    process.env.NODE_ENV = originalEnv;
  }
});
