# GuffSuff MVP Scope & Boundary Definition

> **Document Status**: Complete (Phase 1 Architecture)  
> **Product Positioning**: Secure, Privacy-Focused, Nepal-First Multilingual Communication Platform

---

## 1. Product Positioning & Non-Branding Rules

GuffSuff (गफगाफ / गफसफ) is positioned as a **secure Nepal-first messaging platform** built from scratch with original branding, original user interface designs, and privacy-preserving architecture.

### Non-Copying Guarantee
- **No WhatsApp UI Cloning**: Custom original typography, color palette, custom icons, and unique layout density.
- **No Trademark Infringement**: No copied assets, sound clips, marketing copy, or proprietary trade dress.
- **Original Source Code**: 100% custom codebase in Flutter, NestJS, and shared contracts.

---

## 2. In-Scope MVP Capabilities

| Domain | Included MVP Feature |
| :--- | :--- |
| **Authentication** | Phone number registration (+977 Nepal format validation, E.164 normalization), OTP verification, resend cooldowns, hashed OTP storage, registration PIN lock. |
| **Identity & Profile** | User profile creation, unique `@username`, display name, bio, profile photo, optional discoverability by phone number. |
| **Contacts** | Privacy-preserving contact discovery (local normalization, zero raw address book uploads). |
| **1-to-1 Messaging** | End-to-end encrypted direct text messaging, reply, message copy, edit (within 15-minute window), delete for me, delete for everyone (within 1-hour window). |
| **Group Messaging** | End-to-end encrypted group chat, group creation, member add/remove, admin role assignment, group title/avatar updates, invite link handling. |
| **Message States** | Sent, Delivered, Read receipt indicators, live typing indicators, online/last-seen status (with granular privacy controls). |
| **Encrypted Media** | Client-side AES-GCM encrypted images, documents (PDF, DOCX), audio files, voice notes (recorded in-app), basic location preview. |
| **Privacy & Security** | Disappearing messages (configurable retention: 24h, 7d, 90d), user blocking, user report submission, linked device management & remote session revocation. |
| **Localization & UX** | Full Devanagari Nepali and English localization, dynamic font scaling, dark/light themes, offline local message queueing, data saver mode. |
| **Trust & Safety** | Separate administrative web console with RBAC, report triage, user restrictions, and zero plaintext message access. |
| **Data Rights** | In-app data export request, permanent account deletion workflow. |

---

## 3. Explicit Post-MVP Deferred Features

The following features are **explicitly excluded** from the initial MVP release:

- ❌ Voice Calling (WebRTC audio calls)
- ❌ Video Calling (WebRTC video calls)
- ❌ Stories / Status updates
- ❌ Public broadcast channels
- ❌ Large public communities / forums
- ❌ In-app payments / mobile wallet integration
- ❌ Advertisements & promotional SDKs
- ❌ Automated conversational bots / AI assistants
- ❌ Business / verified enterprise accounts
- ❌ Native Desktop client (Windows/macOS/Linux)
- ❌ Web messaging client
- ❌ Encrypted cloud backup to Google Drive / iCloud
- ❌ Live real-time GPS location tracking
