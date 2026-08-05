import { Queue, Worker, QueueOptions, WorkerOptions } from "bullmq";
import Redis from "ioredis";

export function createRedisConnection(): Redis {
  const url = process.env.REDIS_URL || "redis://localhost:6379";
  return new Redis(url, { maxRetriesPerRequest: null });
}

export function createHealthCheckQueue(connection: Redis): Queue {
  const options: QueueOptions = { connection };
  return new Queue("health-check-queue", options);
}

export function createHealthCheckWorker(connection: Redis): Worker {
  const options: WorkerOptions = { connection };
  return new Worker(
    "health-check-queue",
    async (job) => {
      console.log(`[QUEUE-HEALTH-JOB] Executed harmless health job ID: ${job.id}`);
      return { status: "SUCCESS", timestamp: new Date().toISOString() };
    },
    options
  );
}
