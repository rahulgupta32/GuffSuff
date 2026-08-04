# GuffSuff API Specification

> **Status**: Initial Draft (Phase 0 Bootstrap)  
> **Base Path**: `/api/v1`

---

## 1. Core Resource Endpoints

- `POST /api/v1/auth/otp/request` - Request OTP code for phone number
- `POST /api/v1/auth/otp/verify` - Verify OTP code and obtain session tokens
- `POST /api/v1/account/profile` - Set user profile and display details
- `GET /api/v1/keys/prekey` - Fetch prekey bundle for target user device
- `POST /api/v1/messages/envelope` - Submit encrypted message envelope for delivery
- `POST /api/v1/attachments/upload-url` - Request presigned encrypted attachment upload URL
- `POST /api/v1/contacts/discover` - Privacy-preserving contact discovery
