import { createRedisConnection, createHealthCheckWorker } from "@guffsuff/queue";

async function bootstrap() {
  console.log("[WORKER-SERVICE] Initializing BullMQ Worker service...");
  const connection = createRedisConnection();
  const worker = createHealthCheckWorker(connection);

  process.on("SIGTERM", async () => {
    console.log("[WORKER-SERVICE] Gracefully shutting down worker...");
    await worker.close();
    await connection.quit();
    process.exit(0);
  });
}

bootstrap();
