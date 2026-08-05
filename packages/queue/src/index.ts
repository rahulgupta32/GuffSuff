import { Queue, Worker, QueueOptions, WorkerOptions } from "bullmq";
import Redis from "ioredis";

export function getEnvironmentKeyPrefix(env = process.env.NODE_ENV || "development"): string {
  return `guffsuff:${env}:`;
}

export function createRedisConnection(): Redis {
  const url = process.env.REDIS_URL || "redis://localhost:6379";
  return new Redis(url, { maxRetriesPerRequest: null, keyPrefix: getEnvironmentKeyPrefix() });
}

export function createHealthCheckQueue(connection: Redis, env?: string): Queue {
  const options: QueueOptions = {
    connection,
    prefix: `{${getEnvironmentKeyPrefix(env)}bull}`
  };
  return new Queue("health-check-queue", options);
}

export function createHealthCheckWorker(connection: Redis, env?: string): Worker {
  const options: WorkerOptions = {
    connection,
    prefix: `{${getEnvironmentKeyPrefix(env)}bull}`
  };
  return new Worker(
    "health-check-queue",
    async (job) => {
      console.log(`[QUEUE-HEALTH-JOB] Executed harmless health job ID: ${job.id}`);
      return { status: "SUCCESS", timestamp: new Date().toISOString() };
    },
    options
  );
}
