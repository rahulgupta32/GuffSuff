# GuffSuff Open Business & Architecture Questions

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Warning**: GuffSuff does not yet contain production end-to-end encryption and must not be marketed or represented as cryptographically secure until implementation, independent review, and release acceptance gates are completed.

---

## 1. Decision Status Vocabulary

All entries utilize the standardized GuffSuff decision-status vocabulary:

- **Proposed**: Initial architectural recommendation submitted for review.
- **Under evaluation**: Active technical prototyping or security evaluation underway.
- **Approved by product owner**: Explicitly accepted by `@rahulgupta32` with recorded date and evidence.
- **Approved by security review**: Accepted by Lead Security Reviewer following formal review.
- **Pending benchmark**: Awaiting performance, load, or latency testing under realistic conditions.
- **Rejected**: Explicitly evaluated and declined.
- **Superseded**: Replaced by a newer decision record.

---

## 2. Business & Policy Decision Matrix

| #      | Question / Policy Area         | Recommended Choice                                      | Decision Status    | Notes / Rationale                                                                                      |
| :----- | :----------------------------- | :------------------------------------------------------ | :----------------- | :----------------------------------------------------------------------------------------------------- |
| **1**  | Repository Visibility          | **Private** initially, open-source after security audit | `Proposed`         | Prevents zero-day vulnerability exploitation prior to launch sign-off.                                 |
| **2**  | Initial Group Member Limit     | **256 members**                                         | `Proposed`         | Keeps E2EE pairwise key fan-out computational overhead manageable on mobile devices.                   |
| **3**  | Maximum Attachment Size        | **50 MB**                                               | `Proposed`         | Balances bandwidth costs with user media expectations in Nepal.                                        |
| **4**  | Max Concurrent Linked Devices  | **5 devices**                                           | `Proposed`         | Covers primary phone, secondary phone, and future desktop/tablet apps.                                 |
| **5**  | Message Edit Window            | **15 minutes**                                          | `Proposed`         | Prevents retroactive manipulation of conversational history.                                           |
| **6**  | Delete-for-Everyone Window     | **60 minutes**                                          | `Proposed`         | Standard window for revoking accidental messages.                                                      |
| **7**  | Undelivered Envelope Retention | **30 days**                                             | `Proposed`         | Purges un-retrieved message envelopes from PostgreSQL if recipient stays offline > 30d.                |
| **8**  | Delivered Envelope Retention   | **7 days**                                              | `Under evaluation` | Re-evaluating multi-device offline history sync policy in Phase 2.                                     |
| **9**  | Default Disappearing Messages  | **Off by default**                                      | `Proposed`         | User can enable per chat (options: 24h, 7d, 90d).                                                      |
| **10** | Default Read Receipts          | **Enabled**                                             | `Proposed`         | User can toggle off in Privacy settings.                                                               |
| **11** | Default Last Seen Visibility   | **My Contacts**                                         | `Proposed`         | Protects privacy against arbitrary non-contacts.                                                       |
| **12** | Phone Number Discoverability   | **Contacts Only**                                       | `Proposed`         | Prevents platform-wide contact enumeration scraping.                                                   |
| **13** | Username Change Limits         | **1 change per 14 days**                                | `Proposed`         | Limits impersonation abuse.                                                                            |
| **14** | Min Supported Android Version  | **Android 7.0 (API 24)**                                | `Proposed`         | Covers ~98% of active Android devices in Nepal.                                                        |
| **15** | Min Supported iOS Version      | **iOS 15.0**                                            | `Proposed`         | Supported by iPhone 6s and newer.                                                                      |
| **16** | Initial OTP Provider           | **Unselected** (Sparrow SMS & Twilio under evaluation)  | `Under evaluation` | Phase 2 defines provider security, delivery SLA, and SMS-pumping requirements before vendor selection. |
| **17** | Initial Cloud Provider         | **AWS (`ap-south-1`) or GCP (`asia-south1`)**           | `Under evaluation` | Evaluating lowest network latency (< 45ms) to Nepal telecom backbones.                                 |
| **18** | Initial Deployment Region      | **Mumbai (`ap-south-1` / `asia-south1`)**               | `Proposed`         | Geographic proximity to Nepal.                                                                         |
| **19** | Location Sharing in MVP        | **Static snapshot preview only**                        | `Proposed`         | Live GPS tracking deferred to post-MVP.                                                                |
| **20** | Voice Notes in MVP             | **Yes (In-app audio recording)**                        | `Proposed`         | Critical for audio-first communication in Nepal.                                                       |
| **21** | Cloud Backup in v1             | **Excluded entirely from v1**                           | `Proposed`         | Eliminates risk of unencrypted cloud key leakage.                                                      |
| **22** | Legal Entity & Owner           | **Rahul Gupta (`@rahulgupta32`)**                       | `Under evaluation` | Primary product maintainer and project owner.                                                          |
| **23** | Support Response SLA           | **24h High, 72h Normal**                                | `Proposed`         | SLA for user reports and account help.                                                                 |
| **24** | Expected Initial DAU           | **10,000 DAU**                                          | `Proposed`         | Initial launch capacity target.                                                                        |
| **25** | Expected 6-Month DAU           | **100,000 DAU**                                         | `Proposed`         | Scale target for infra planning.                                                                       |
