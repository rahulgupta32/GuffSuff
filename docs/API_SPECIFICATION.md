# GuffSuff API Specification v1

> **Document Status**: Complete (Phase 1 Specification)  
> **Base Path**: `/api/v1`  
> **Format**: REST over HTTPS, JSON payloads, OpenAPI 3.0 compatible  
> **Authentication**: Bearer JWT (`Authorization: Bearer <access_token>`)

---

## 1. Global API Standards

### Standard Error Response Envelope
```json
{
  "error": {
    "code": "AUTH_INVALID_OTP",
    "message": "The verification code provided is invalid or has expired.",
    "timestamp": "2026-08-05T05:15:00.000Z",
    "correlationId": "018e3a99-4b12-7890-a123-987654321abc",
    "details": []
  }
}
```

---

## 2. API Endpoint Groups

### Authentication & Account Recovery (`/api/v1/auth`)

#### `POST /api/v1/auth/otp/request`
- **Purpose**: Request OTP verification code for a mobile phone number.
- **Auth**: None (Public rate-limited endpoint).
- **Request Body**:
  ```json
  {
    "phoneNumber": "+9779841234567",
    "captchaToken": "optional_captcha_string"
  }
  ```
- **Rate Limit**: Max 3 requests per phone number per 15 minutes; 60s resend cooldown.
- **Response**: `200 OK` `{"status": "SENT", "resendAvailableInSeconds": 60}`.

#### `POST /api/v1/auth/otp/verify`
- **Purpose**: Verify OTP code and obtain session JWTs.
- **Auth**: None.
- **Request Body**:
  ```json
  {
    "phoneNumber": "+9779841234567",
    "otp": "123456",
    "deviceInfo": {
      "identifier": "device_uuid_string",
      "name": "Redmi Note 12",
      "platform": "ANDROID"
    }
  }
  ```
- **Response**: `200 OK` `{"accessToken": "<jwt>", "refreshToken": "<jwt>", "expiresIn": 900, "user": {"id": "<uuidv7>", "isNewUser": true}}`.

---

### Key Bundles & E2EE Management (`/api/v1/keys`)

#### `POST /api/v1/keys/publish`
- **Purpose**: Publish device public prekey bundle.
- **Auth**: Bearer JWT.
- **Request Body**: Identity key, signed prekey, signed prekey signature, one-time prekeys array.

#### `GET /api/v1/keys/prekey/:userId/:deviceId`
- **Purpose**: Fetch public key bundle for establishing asynchronous E2EE session with target device.
- **Auth**: Bearer JWT.
- **Response**: Target device public keys.

---

### Contact Discovery (`/api/v1/contacts`)

#### `POST /api/v1/contacts/discover`
- **Purpose**: Match phone numbers via salted HMAC hashes without uploading raw address book.
- **Auth**: Bearer JWT.
- **Rate Limit**: Max 50 queries per hour per account.
- **Request Body**: `{"phoneHashes": ["sha256_hash_1", "sha256_hash_2"]}`.
- **Response**: Matched users array `[{"userId": "<uuidv7>", "username": "@user", "phoneHash": "..."}]`.

---

### Messages & Attachments (`/api/v1/messages`, `/api/v1/attachments`)

#### `POST /api/v1/messages/envelope`
- **Purpose**: Submit encrypted message envelope for offline recipient device queueing.
- **Auth**: Bearer JWT.
- **Header**: `X-Idempotency-Key: <uuidv7>`

#### `POST /api/v1/attachments/upload-url`
- **Purpose**: Request short-lived presigned upload URL for client-side encrypted media blob.
- **Auth**: Bearer JWT.
- **Response**: `{"uploadUrl": "https://s3.guffsuff.com/...", "objectKey": "media_uuid.enc", "expiresIn": 900}`.

---

### User Actions, Devices, Admin & Compliance (`/api/v1/user`, `/api/v1/devices`, `/api/v1/admin`)
- Includes endpoints for profile setup, device listing/revocation, block/report user, account export request, and account deletion request.
