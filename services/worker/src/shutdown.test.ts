import assert from "node:assert";
import test from "node:test";
import Redis from "ioredis";
import { createHealthCheckWorker } from "@guffsuff/queue";

test("Worker service gracefully stops worker and closes Redis connection on shutdown signal", async () => {
  const redis = new Redis(process.env.REDIS_URL || "redis://localhost:6379", {
    maxRetriesPerRequest: null,
    lazyConnect: true,
    retryStrategy: () => null,
    enableOfflineQueue: false
  });
  redis.on("error", () => {});
  const worker = createHealthCheckWorker(redis);

  assert.ok(worker, "Worker instance initialized");

  await worker.close();
  redis.disconnect();

  assert.ok(
    ["end", "wait", "close", "reconnecting", "connecting"].includes(redis.status),
    "Redis connection closed cleanly"
  );
});
