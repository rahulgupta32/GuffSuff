import { z } from "zod";

export const HealthResponseSchema = z.object({
  status: z.enum(["OK", "DEGRADED", "UNHEALTHY"]),
  service: z.string(),
  version: z.string(),
  timestamp: z.string().datetime()
});
export type HealthResponse = z.infer<typeof HealthResponseSchema>;

export const ReadinessResponseSchema = z.object({
  ready: z.boolean(),
  service: z.string(),
  checks: z.record(z.boolean()),
  timestamp: z.string().datetime()
});
export type ReadinessResponse = z.infer<typeof ReadinessResponseSchema>;

export const StandardErrorResponseSchema = z.object({
  errorCode: z.string(),
  message: z.string(),
  correlationId: z.string().uuid(),
  timestamp: z.string().datetime(),
  details: z.record(z.unknown()).optional()
});
export type StandardErrorResponse = z.infer<typeof StandardErrorResponseSchema>;

export const RequestMetadataSchema = z.object({
  correlationId: z.string().uuid(),
  idempotencyKey: z.string().optional(),
  clientVersion: z.string().optional(),
  platform: z.enum(["android", "ios", "web", "server"]).optional()
});
export type RequestMetadata = z.infer<typeof RequestMetadataSchema>;

export const PaginationQuerySchema = z.object({
  limit: z.number().int().min(1).max(100).default(20),
  cursor: z.string().optional()
});
export type PaginationQuery = z.infer<typeof PaginationQuerySchema>;

export const RealtimeEventEnvelopeSchema = z.object({
  eventId: z.string().uuid(),
  eventType: z.string(),
  correlationId: z.string().uuid(),
  timestamp: z.number().int().positive(),
  payload: z.record(z.unknown())
});
export type RealtimeEventEnvelope = z.infer<typeof RealtimeEventEnvelopeSchema>;

export const OpaqueEncryptedPayloadPlaceholderSchema = z.object({
  version: z.number().int().positive(),
  ephemeralSenderPublicKey: z.string(),
  ciphertextBlob: z.string(),
  mac: z.string()
});
export type OpaqueEncryptedPayloadPlaceholder = z.infer<
  typeof OpaqueEncryptedPayloadPlaceholderSchema
>;
