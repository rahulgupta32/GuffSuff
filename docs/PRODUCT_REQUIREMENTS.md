# GuffSuff Product Requirements Document (PRD)

> **Status**: Initial Draft (Phase 0 Bootstrap)  
> **Target Launch Market**: Nepal (Primary: Nepali + Devanagari, Secondary: English)  
> **Platforms**: Android, iOS, Administrative Web Console, Realtime Backend Services  

---

## 1. Vision & Core Philosophy

GuffSuff (गफगाफ / गफसफ) is a modern, privacy-focused, Nepal-first communication platform built with zero proprietary branding copies, original source code, and custom architecture tailored for high reliability across varying network conditions (+977 2G/3G/4G/Wi-Fi).

---

## 2. MVP Functional Requirements Checklist

- [ ] Phone-number registration (+977 Nepal format validation, E.164 normalization)
- [ ] OTP verification (Progressive cooldowns, secure hashed OTP storage)
- [ ] User profile creation & unique username support
- [ ] Privacy-preserving contact discovery
- [ ] One-to-one text messaging (End-to-End Encrypted)
- [ ] Group messaging with group administration controls
- [ ] Message status: Sent, Delivered, Read states with timestamping
- [ ] Typing indicators & Online/Last-Seen privacy controls
- [ ] Image, video, audio, document, and location sharing (Encrypted uploads)
- [ ] Voice notes recording and playback
- [ ] Disappearing messages (configurable retention per conversation)
- [ ] User blocking & abuse reporting workflows
- [ ] Multi-device architecture readiness & device revocation
- [ ] Device-side message search over local decrypted SQLite/Drift database
- [ ] English and Nepali (Devanagari script) localization
- [ ] Data export & complete account deletion (GDPR/Nepal privacy compliance)

---

## 3. Non-Functional Requirements

- **Performance**: Sub-100ms API latency, sub-200ms WebSocket delivery under normal network.
- **Reliability**: Graceful retry and local offline queueing for intermittent connections.
- **Accessibility**: High contrast ratio, scalable dynamic fonts, full Devanagari shaping without truncated matras.
