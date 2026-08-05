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

/* Phase 4 Identity Schemas */

export const UsernameRegex = /^[a-z0-9_]{3,20}$/;

export const OtpRequestSchema = z.object({
  phoneNumber: z.string().min(5).max(30),
  installationId: z.string().min(1).max(128),
  deviceName: z.string().min(1).max(100),
  platform: z.enum(["android", "ios", "web", "desktop"]),
  appVersion: z.string().min(1).max(32),
  osVersion: z.string().min(1).max(32)
});
export type OtpRequest = z.infer<typeof OtpRequestSchema>;

export const OtpVerifySchema = z.object({
  challengeId: z.string().uuid(),
  otpCode: z.string().length(6).regex(/^\d{6}$/)
});
export type OtpVerify = z.infer<typeof OtpVerifySchema>;

export const RegisterAccountSchema = z.object({
  challengeId: z.string().uuid(),
  displayName: z.string().min(2).max(50),
  username: z.string().regex(UsernameRegex, "Username must be 3-20 lowercase ASCII letters, numbers, or underscore"),
  locale: z.string().default("ne"),
  timezone: z.string().default("Asia/Kathmandu"),
  termsAccepted: z.literal(true, {
    errorMap: () => ({ message: "Terms must be accepted" })
  }),
  privacyAccepted: z.literal(true, {
    errorMap: () => ({ message: "Privacy policy must be accepted" })
  })
});
export type RegisterAccount = z.infer<typeof RegisterAccountSchema>;

export const TokenRefreshSchema = z.object({
  refreshToken: z.string().min(1)
});
export type TokenRefresh = z.infer<typeof TokenRefreshSchema>;

export const UpdateProfileSchema = z.object({
  displayName: z.string().min(2).max(50).optional(),
  bio: z.string().max(255).optional()
});
export type UpdateProfile = z.infer<typeof UpdateProfileSchema>;

export const CheckUsernameSchema = z.object({
  username: z.string().regex(UsernameRegex)
});
export type CheckUsername = z.infer<typeof CheckUsernameSchema>;

export const UpdateUsernameSchema = z.object({
  username: z.string().regex(UsernameRegex)
});
export type UpdateUsername = z.infer<typeof UpdateUsernameSchema>;

export const PrivacyVisibilityEnum = z.enum(["everyone", "contacts_only", "nobody"]);

export const UpdatePrivacySettingsSchema = z.object({
  lastSeenVisibility: PrivacyVisibilityEnum.optional(),
  onlineStatusVisibility: PrivacyVisibilityEnum.optional(),
  profilePhotoVisibility: PrivacyVisibilityEnum.optional(),
  phoneNumberVisibility: PrivacyVisibilityEnum.optional(),
  readReceipts: z.boolean().optional(),
  phoneDiscoverability: z.boolean().optional(),
  securityNotifications: z.boolean().optional(),
  notificationPreviews: z.boolean().optional()
});
export type UpdatePrivacySettings = z.infer<typeof UpdatePrivacySettingsSchema>;

export const UpdateDeviceSchema = z.object({
  deviceName: z.string().min(1).max(100)
});
export type UpdateDevice = z.infer<typeof UpdateDeviceSchema>;

export const SetRegistrationLockPinSchema = z.object({
  pin: z.string().min(6).max(12).regex(/^\d{6,12}$/)
});
export type SetRegistrationLockPin = z.infer<typeof SetRegistrationLockPinSchema>;

export const VerifyRegistrationLockPinSchema = z.object({
  pin: z.string().min(6).max(12).regex(/^\d{6,12}$/)
});
export type VerifyRegistrationLockPin = z.infer<typeof VerifyRegistrationLockPinSchema>;

/* Phase 5 Opaque Encrypted Envelope Transport Schemas */

export const CreateDirectConversationSchema = z.object({
  recipientUserId: z.string().uuid()
});
export type CreateDirectConversation = z.infer<typeof CreateDirectConversationSchema>;

export const SubmitMessageEnvelopeSchema = z.object({
  idempotencyKey: z.string().min(1).max(64),
  conversationId: z.string().uuid(),
  recipientUserId: z.string().uuid(),
  protocolVersion: z.number().int().positive().default(1),
  opaquePayloadBase64: z.string().min(1).max(87382), // Max 64KB base64 encoded
  clientCreatedAt: z.string().datetime(),
  expiresAt: z.string().datetime()
});
export type SubmitMessageEnvelope = z.infer<typeof SubmitMessageEnvelopeSchema>;

export const AcknowledgeDeliverySchema = z.object({
  recipientDeviceId: z.string().uuid().optional()
});
export type AcknowledgeDelivery = z.infer<typeof AcknowledgeDeliverySchema>;

export const AcknowledgeReadSchema = z.object({
  lastReadEnvelopeId: z.string().uuid()
});
export type AcknowledgeRead = z.infer<typeof AcknowledgeReadSchema>;
