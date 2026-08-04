# GuffSuff Open Business & Product Questions

> **Document Status**: Complete (Phase 1 Specification)  
> **Status Tag**: All recommendations are `PENDING USER APPROVAL`.

---

## Business & Policy Decision Matrix

| # | Question / Policy Area | Recommended Choice | Status | Notes / Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **1** | Repository Visibility | **Private** initially, open-source after security audit | `PENDING APPROVAL` | Prevents zero-day vulnerability exploitation prior to launch sign-off. |
| **2** | Initial Group Member Limit | **256 members** | `PENDING APPROVAL` | Keeps E2EE pairwise key fan-out computational overhead manageable on mobile devices. |
| **3** | Maximum Attachment Size | **50 MB** | `PENDING APPROVAL` | Balances bandwidth costs with user media expectations in Nepal. |
| **4** | Max Concurrent Linked Devices | **5 devices** | `PENDING APPROVAL` | Covers primary phone, secondary phone, and future desktop/tablet apps. |
| **5** | Message Edit Window | **15 minutes** | `PENDING APPROVAL` | Prevents retroactive manipulation of conversational history. |
| **6** | Delete-for-Everyone Window | **60 minutes** | `PENDING APPROVAL` | Standard window for revoking accidental messages. |
| **7** | Undelivered Envelope Retention | **30 days** | `PENDING APPROVAL` | Purges un-retrieved message envelopes from PostgreSQL if recipient stays offline > 30d. |
| **8** | Delivered Envelope Retention | **7 days** | `PENDING APPROVAL` | Server purges delivered opaque envelopes after 7 days; messages persist only on devices. |
| **9** | Default Disappearing Messages | **Off by default** | `PENDING APPROVAL` | User can enable per chat (options: 24h, 7d, 90d). |
| **10**| Default Read Receipts | **Enabled** | `PENDING APPROVAL` | User can toggle off in Privacy settings. |
| **11**| Default Last Seen Visibility | **My Contacts** | `PENDING APPROVAL` | Protects privacy against arbitrary non-contacts. |
| **12**| Phone Number Discoverability | **Contacts Only** | `PENDING APPROVAL` | Prevents platform-wide contact enumeration scraping. |
| **13**| Username Change Limits | **1 change per 14 days** | `PENDING APPROVAL` | Limits impersonation abuse. |
| **14**| Min Supported Android Version | **Android 7.0 (API 24)** | `PENDING APPROVAL` | Covers ~98% of active Android devices in Nepal. |
| **15**| Min Supported iOS Version | **iOS 15.0** | `PENDING APPROVAL` | Supported by iPhone 6s and newer. |
| **16**| Initial OTP Provider | **Sparrow SMS (Primary)** + Twilio (Fallback) | `PENDING APPROVAL` | Sparrow SMS offers direct local telecom routing in Nepal (+977). |
| **17**| Initial Cloud Provider | **AWS (`ap-south-1`) or GCP (`asia-south1`)** | `PENDING APPROVAL` | Lowest latency (< 45ms) to Nepal internet exchanges. |
| **18**| Initial Deployment Region | **Mumbai, India** | `PENDING APPROVAL` | Geographic proximity to Nepal. |
| **19**| Location Sharing in MVP | **Static snapshot preview only** | `PENDING APPROVAL` | Live GPS tracking deferred to post-MVP. |
| **20**| Voice Notes in MVP | **Yes (In-app audio recording)** | `PENDING APPROVAL` | Critical for audio-first communication in Nepal. |
| **21**| Cloud Backup in v1 | **Excluded entirely from v1** | `PENDING APPROVAL` | Eliminates risk of unencrypted cloud key leakage. |
| **22**| Legal Entity & Owner | **Rahul Gupta (`@rahulgupta32`)** | `PENDING APPROVAL` | Primary product maintainer. |
| **23**| Support Response SLA | **24h High, 72h Normal** | `PENDING APPROVAL` | SLA for user reports and account help. |
| **24**| Expected Initial DAU | **10,000 DAU** | `PENDING APPROVAL` | Initial launch capacity target. |
| **25**| Expected 6-Month DAU | **100,000 DAU** | `PENDING APPROVAL` | Scale target for infra planning. |
