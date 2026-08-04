# GuffSuff Product Requirements Document (PRD)

> **Document Status**: Complete (Phase 1 Specification)  
> **Market Target**: Nepal (Primary: Nepali Devanagari, Secondary: English)

---

## 1. User Personas

1. **Prashant (Everyday Nepali Mobile User)**: Uses budget Android phone on Ncell/NTC 3G/4G. Expects fast messaging, simple media sharing, and intuitive UI in Nepali.
2. **Sarita (Low-Bandwidth / Rural User)**: Lives in remote district with intermittent 2G/Wi-Fi connection. Requires low-data overhead, background message retries, and offline queueing.
3. **Bikram (First-Time Smartphone User)**: Prefers Devanagari text presentation, large touch targets, accessible contrast, and zero confusing technical jargon.
4. **Kriti (Student / Family Group Admin)**: Coordinates college assignments and family chats. Needs reliable E2EE group messaging, admin controls, and media sharing.
5. **Aashish (Privacy-Conscious Professional)**: Demands verified end-to-end encryption, disappearing messages, device revocation, and zero metadata leakage.
6. **Sunita (Support Agent)**: Admin console user assisting users with OTP or account recovery without reading private message text.
7. **Ramesh (Trust & Safety Analyst)**: Reviews encrypted abuse reports, metadata signals, and handles account restrictions via RBAC.
8. **DevOps Engineer**: Monitors platform health, Redis pub/sub delivery metrics, and PostgreSQL query latencies.

---

## 2. Functional Requirements Matrix (MoSCoW Prioritization)

### Authentication & Identity
- **AUTH-001** (Must Have): Nepal Phone E.164 Normalization. Validates +977 mobile numbers (98xxxxxxxx, 97xxxxxxxx) and normalizes to E.164. Prevents invalid numbers from consuming OTP quota.
- **AUTH-002** (Must Have): Cryptographic OTP Verification. Generates secure 6-digit OTP, stores argon2id/bcrypt hash with 5-minute TTL, enforces max 3 verification attempts and 60s resend cooldown.
- **AUTH-003** (Must Have): Registration Lock PIN. Optional 6-digit PIN required during account re-registration to prevent SIM-swap account takeover.

### User & Device Management
- **USER-001** (Must Have): Profile & Unique Username. Users establish a display name and unique `@username` (3-30 chars, alphanumeric + underscore).
- **DEVICE-001** (Must Have): Device Identity & Revocation. Assigns unique UUIDv7 per registered device with public key bundle. Supports listing active sessions and remote revocation.

### Contact Discovery & Privacy
- **DISCOVERY-001** (Must Have): Privacy-Preserving Contact Matching. Computes local salted HMAC-SHA256 hashes of normalized contact numbers for server lookup. Raw address books are never stored server-side.
- **PRIVACY-001** (Must Have): Granular Privacy Controls. Configurable visibility for Last Seen (Everyone / Contacts / Nobody), Read Receipts (On / Off), and Profile Photo.

### Encrypted Messaging & Groups
- **CHAT-001** (Must Have): One-to-One E2EE Text Messaging. Asynchronous end-to-end encrypted direct messaging with delivery & read state receipts.
- **GROUP-001** (Must Have): Encrypted Group Messaging. Supports group creation (up to 256 members for MVP), member management, and admin role delegation.
- **MESSAGE-001** (Must Have): Message Lifecycle Actions. Reply, reaction (emoji), message edit (within 15 mins), delete for self, delete for everyone (within 60 mins).
- **MEDIA-001** (Must Have): Encrypted Attachment Transfer. Client-side AES-256-GCM encryption for images, PDFs, audio notes, and voice recordings uploaded to private S3 buckets.

### Abuse & Trust
- **ABUSE-001** (Must Have): One-Tap Block & User Reporting. Allows blocking users and submitting encrypted report envelopes to Trust & Safety analysts.
- **ADMIN-001** (Must Have): Admin Console RBAC. Role-based web console for support/T&S with immutable audit logging and ZERO message plaintext access.

### Compliance & Rights
- **EXPORT-001** (Must Have): In-App Data Export. Generates encrypted downloadable zip of user profile and account metadata.
- **DELETE-001** (Must Have): Account Deletion. Permanently purges user account records, device keys, and prekeys from production database within 30 days.
- **LOCALIZATION-001** (Must Have): Multilingual Nepali/English UI. Complete translation files in ARB format supporting proper Devanagari script shaping.
- **ACCESSIBILITY-001** (Must Have): Accessibility Baseline. Minimum 4.5:1 contrast ratio, WCAG 2.1 AA compliance, dynamic font scaling support.
