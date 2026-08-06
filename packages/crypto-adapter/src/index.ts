/**
 * @file packages/crypto-adapter/src/index.ts
 * @description Typed Cryptographic Adapter Interfaces for GuffSuff.
 *
 * SECURITY WARNING:
 * This package defines typed contracts and interfaces ONLY.
 * It DOES NOT contain cryptographic algorithm implementations, production key generation,
 * or fake/mock encryption providers. Application code MUST depend exclusively on these
 * abstraction interfaces.
 */

// Opaque Key & State Handles (Prevents unsafe raw key exposure)
export type OpaqueIdentityKeyHandle = {
  readonly __brand: "OpaqueIdentityKeyHandle";
  readonly keyId: string;
};
export type OpaqueSessionStateHandle = {
  readonly __brand: "OpaqueSessionStateHandle";
  readonly sessionId: string;
};
export type OpaqueGroupStateHandle = {
  readonly __brand: "OpaqueGroupStateHandle";
  readonly groupId: string;
  readonly epoch: number;
};

// Public Prekey Bundle Structure (Non-sensitive public key data)
export interface PublicPrekeyBundle {
  deviceId: string;
  identityPublicKeyBase64: string;
  signedPrekeyId: number;
  signedPrekeyPublicBase64: string;
  signedPrekeySignatureBase64: string;
  oneTimePrekeyPublicBase64?: string;
  oneTimePrekeyId?: number;
}

// Encrypted Payload Structures
export interface EncryptedEnvelopePayload {
  protocolVersion: number;
  ephemeralPublicKeyBase64: string;
  ciphertextBase64: string;
  messageType: "PREKEY_SIGNAL" | "WHISPER_SIGNAL" | "MLS_GROUP";
}

export interface AttachmentEncryptionResult {
  ciphertextObjectKey: string;
  mediaKeyBase64: string;
  ivBase64: string;
  macBase64: string;
  sizeBytes: number;
}

// Structured Failure Error Classes
export type CryptoErrorCode =
  | "INVALID_SIGNATURE"
  | "UNKNOWN_DEVICE"
  | "STALE_KEY_BUNDLE"
  | "REPLAY_ATTACK"
  | "UNSUPPORTED_VERSION"
  | "CORRUPTED_CIPHERTEXT"
  | "AUTHENTICATION_FAILURE"
  | "REVOKED_DEVICE"
  | "GROUP_EPOCH_MISMATCH"
  | "MISSING_SESSION"
  | "KEY_STORAGE_UNAVAILABLE";

export class CryptoAdapterError extends Error {
  constructor(
    public readonly code: CryptoErrorCode,
    message: string
  ) {
    super(`[CryptoAdapterError:${code}] ${message}`);
    this.name = "CryptoAdapterError";
  }
}

// Core Cryptographic Interface Contracts

export interface IdentityKeyManager {
  initializeDeviceIdentity(): Promise<OpaqueIdentityKeyHandle>;
  exportPublicDeviceIdentity(handle: OpaqueIdentityKeyHandle): Promise<string>;
  generateVerificationCode(
    localHandle: OpaqueIdentityKeyHandle,
    recipientPublicKeyBase64: string
  ): Promise<string>;
}

export interface PreKeyManager {
  publishPublicKeyBundle(
    handle: OpaqueIdentityKeyHandle,
    count: number
  ): Promise<PublicPrekeyBundle>;
}

export interface SessionManager {
  establishOutboundSession(recipientBundle: PublicPrekeyBundle): Promise<OpaqueSessionStateHandle>;
  processInboundPreKeyMessage(
    inboundMessage: EncryptedEnvelopePayload
  ): Promise<OpaqueSessionStateHandle>;
  encryptForDevices(
    sessionHandles: Map<string, OpaqueSessionStateHandle>,
    plaintext: Uint8Array
  ): Promise<Map<string, EncryptedEnvelopePayload>>;
  decryptEnvelope(
    sessionHandle: OpaqueSessionStateHandle,
    envelope: EncryptedEnvelopePayload
  ): Promise<Uint8Array>;
  revokeDevice(deviceId: string): Promise<void>;
}

export interface GroupSessionManager {
  createGroupState(groupId: string, memberDeviceIds: string[]): Promise<OpaqueGroupStateHandle>;
  addGroupMember(
    groupHandle: OpaqueGroupStateHandle,
    newMemberDeviceId: string,
    newMemberBundle: PublicPrekeyBundle
  ): Promise<OpaqueGroupStateHandle>;
  removeGroupMember(
    groupHandle: OpaqueGroupStateHandle,
    removedMemberDeviceId: string
  ): Promise<OpaqueGroupStateHandle>;
  rotateGroupState(groupHandle: OpaqueGroupStateHandle): Promise<OpaqueGroupStateHandle>;
}

export interface AttachmentCrypto {
  encryptAttachmentStream(
    fileStream: ReadableStream<Uint8Array>
  ): Promise<AttachmentEncryptionResult>;
  decryptAttachmentStream(
    ciphertextStream: ReadableStream<Uint8Array>,
    mediaKeyBase64: string,
    ivBase64: string,
    macBase64: string
  ): Promise<ReadableStream<Uint8Array>>;
}

export interface EnvelopeCodec {
  inspectProtocolVersion(payload: Uint8Array): number;
}

export interface KeyChangeObserver {
  onIdentityKeyChanged(deviceId: string, newPublicKeyBase64: string): void;
}

export interface CryptoMigrationManager {
  migrateSessionState(
    oldHandle: OpaqueSessionStateHandle,
    targetVersion: number
  ): Promise<OpaqueSessionStateHandle>;
}

export type ProviderCapabilityFamily = "DIRECT_MESSAGE_PROVIDER" | "GROUP_MESSAGE_PROVIDER";

export interface ProviderCapabilityMap {
  supportsDirectMessaging: boolean;
  supportsGroupMessaging: boolean;
  supportedProtocolVersions: number[];
  providerId: string;
  providerVersion: string;
  isTestProvider: boolean;
}

export interface CryptoProviderCapabilityQuery {
  queryCapabilities(): ProviderCapabilityMap;
}

export interface CryptoProvider extends CryptoProviderCapabilityQuery {
  identity: IdentityKeyManager;
  prekeys: PreKeyManager;
  sessions: SessionManager;
  groups: GroupSessionManager;
  attachments: AttachmentCrypto;
  codec: EnvelopeCodec;
  migration: CryptoMigrationManager;
}

export class ProviderUnavailableError extends CryptoAdapterError {
  constructor(message: string = "SECURE MESSAGING PROVIDER UNAVAILABLE") {
    super("KEY_STORAGE_UNAVAILABLE", message);
    this.name = "ProviderUnavailableError";
  }
}

export function assertProductionProviderSafety(capabilities: ProviderCapabilityMap, isProductionEnvironment: boolean): void {
  if (isProductionEnvironment && capabilities.isTestProvider) {
    throw new CryptoAdapterError(
      "AUTHENTICATION_FAILURE",
      `PROHIBITED: Test provider '${capabilities.providerId}' cannot be loaded in production environment`
    );
  }
}

