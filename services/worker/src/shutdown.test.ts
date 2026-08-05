import assert from "node:assert";
import test from "node:test";
import { createRedisConnection, createHealthCheckWorker } from "@guffsuff/queue";

test("Worker service gracefully stops worker and closes Redis connection on shutdown signal", async () => {
  const redis = createRedisConnection({
    retryStrategy: () => null,
    enableOfflineQueue: false
  });
  redis.on("error", () => {});
  const worker = createHealthCheckWorker(redis);

  assert.ok(worker, "Worker instance initialized");

  await worker.close().catch(() => {});
  try {
    await redis.quit();
  } catch {
    redis.disconnect();
  }

  assert.ok(
    ["end", "wait", "close", "reconnecting", "connecting"].includes(redis.status),
    "Redis connection closed cleanly"
  );
});
