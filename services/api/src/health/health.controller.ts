import { Controller, Get, HttpException, HttpStatus } from "@nestjs/common";
import { createDatabasePool } from "@guffsuff/database";
import { createRedisConnection } from "@guffsuff/queue";
import { createObjectStorageClient, checkStorageHealth } from "@guffsuff/object-storage";

@Controller()
export class HealthController {
  @Get("health")
  getHealth() {
    return {
      status: "OK",
      service: "api",
      version: "0.1.0-dev",
      timestamp: new Date().toISOString()
    };
  }

  @Get("readiness")
  async getReadiness() {
    let databaseStatus = "DOWN";
    let redisStatus = "DOWN";
    let storageStatus = "DOWN";

    try {
      const pool = createDatabasePool();
      const client = await pool.connect();
      await client.query("SELECT 1");
      client.release();
      await pool.end();
      databaseStatus = "UP";
    } catch {
      databaseStatus = "DOWN";
    }

    try {
      const redis = createRedisConnection();
      const pong = await redis.ping();
      if (pong === "PONG") redisStatus = "UP";
      redis.disconnect();
    } catch {
      redisStatus = "DOWN";
    }

    try {
      const s3Client = createObjectStorageClient();
      const isStorageHealthy = await checkStorageHealth(
        s3Client,
        process.env.S3_BUCKET || "guffsuff-attachments"
      );
      storageStatus = isStorageHealthy ? "UP" : "DOWN";
      s3Client.destroy();
    } catch {
      storageStatus = "DOWN";
    }

    const isReady = databaseStatus === "UP" && redisStatus === "UP";
    const responsePayload = {
      status: isReady ? "READY" : "NOT_READY",
      service: "api",
      dependencies: {
        database: databaseStatus,
        redis: redisStatus,
        storage: storageStatus
      },
      timestamp: new Date().toISOString()
    };

    if (!isReady) {
      throw new HttpException(responsePayload, HttpStatus.SERVICE_UNAVAILABLE);
    }

    return responsePayload;
  }
}
