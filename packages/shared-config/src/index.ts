import { z } from "zod";

export const APP_NAME = "GuffSuff";
export const SUPPORTED_LOCALES = ["ne", "en"] as const;

const booleanSchema = z.union([z.boolean(), z.string()]).transform((val) => {
  if (typeof val === "boolean") return val;
  return val.toLowerCase() === "true" || val === "1";
});

export const EnvironmentConfigSchema = z
  .object({
    NODE_ENV: z.enum(["development", "staging", "production", "test"]),
    PORT: z.coerce.number().default(3000),
    DATABASE_URL: z.string().url(),
    REDIS_URL: z.string().url(),
    S3_ENDPOINT: z.string().url(),
    S3_BUCKET: z.string().min(1),
    JWT_SECRET: z.string().min(32, "JWT secret must be at least 32 characters"),
    CORS_ORIGIN: z.string().min(1),
    ALLOW_MOCK_CRYPTO: booleanSchema.default(false),
    ALLOW_DEV_OTP: booleanSchema.default(false),
    LOG_LEVEL: z.enum(["trace", "debug", "info", "warn", "error", "fatal"]).default("info")
  })
  .superRefine((data, ctx) => {
    const isProdOrStaging = data.NODE_ENV === "production" || data.NODE_ENV === "staging";

    if (isProdOrStaging) {
      if (data.CORS_ORIGIN === "*") {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message:
            "Wildcard CORS origin is strictly forbidden in production and staging environments.",
          path: ["CORS_ORIGIN"]
        });
      }

      if (data.ALLOW_MOCK_CRYPTO) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Mock crypto mode is strictly forbidden in production and staging environments.",
          path: ["ALLOW_MOCK_CRYPTO"]
        });
      }

      if (data.ALLOW_DEV_OTP) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message:
            "Development OTP mode is strictly forbidden in production and staging environments.",
          path: ["ALLOW_DEV_OTP"]
        });
      }
    }

    if (data.NODE_ENV === "production") {
      if (data.LOG_LEVEL === "debug" || data.LOG_LEVEL === "trace") {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Debug/Trace logging is strictly forbidden in production environment.",
          path: ["LOG_LEVEL"]
        });
      }

      if (data.DATABASE_URL.includes("localhost") || data.DATABASE_URL.includes("127.0.0.1")) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Localhost database endpoint is forbidden in production environment.",
          path: ["DATABASE_URL"]
        });
      }

      if (data.REDIS_URL.includes("localhost") || data.REDIS_URL.includes("127.0.0.1")) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Localhost Redis endpoint is forbidden in production environment.",
          path: ["REDIS_URL"]
        });
      }
    }
  });

export type EnvironmentConfig = z.infer<typeof EnvironmentConfigSchema>;

export function validateEnvironmentConfig(rawEnv: Record<string, unknown>): EnvironmentConfig {
  const parseResult = EnvironmentConfigSchema.safeParse(rawEnv);

  if (!parseResult.success) {
    const errorMessages = parseResult.error.issues
      .map((issue) => `[${issue.path.join(".")}] ${issue.message}`)
      .join("; ");
    throw new Error(`FAIL-CLOSED CONFIGURATION FAILURE: ${errorMessages}`);
  }

  return parseResult.data;
}
