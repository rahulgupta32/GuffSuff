import { S3Client, HeadBucketCommand } from "@aws-sdk/client-s3";

export function createObjectStorageClient(): S3Client {
  return new S3Client({
    region: process.env.AWS_REGION || "ap-south-1",
    endpoint: process.env.S3_ENDPOINT || "http://localhost:9000",
    forcePathStyle: true,
    credentials: {
      accessKeyId: process.env.S3_ACCESS_KEY || "guffsuff_minio_local_key",
      secretAccessKey: process.env.S3_SECRET_KEY || "guffsuff_minio_local_secret"
    }
  });
}

export async function checkStorageHealth(client: S3Client, bucketName: string): Promise<boolean> {
  try {
    await client.send(new HeadBucketCommand({ Bucket: bucketName }));
    return true;
  } catch {
    return false;
  }
}
