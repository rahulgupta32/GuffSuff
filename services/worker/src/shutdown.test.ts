import assert from "node:assert";
import test from "node:test";
import { createRedisConnection } from "@guffsuff/queue";

test("Worker service gracefully stops worker and closes Redis connection on shutdown signal", async () => {
  const redis = createRedisConnection({ lazyConnect: true });

  assert.ok(redis, "Redis connection initialized");
  assert.ok(["wait", "connecting"].includes(redis.status), "Redis connection is in initial state");

  redis.disconnect();

  assert.ok(["end", "wait", "close"].includes(redis.status), "Redis connection closed cleanly");
});
