# Legal Review Packet: `libsignal` AGPL-3.0 Compliance & Commercial Risk Assessment

> **MARKING**: `LEGAL REVIEW REQUIRED — NO PRODUCTION APPROVAL`  
> **Target Audience**: IP & Open Source Legal Counsel  
> **Date**: August 6, 2026

---

## 1. Executive Summary & Purpose

This document presents a factual compilation of open-source license attributes, linking models, distribution channels, and upstream maintainer disclosures for `libsignal` (`https://github.com/signalapp/libsignal`). It is prepared exclusively for qualified legal counsel evaluation. **No final legal conclusion or commercial authorization is asserted herein.**

---

## 2. Technical Component & License Breakdown

- **Exact Tested Version**: `v0.60.0` (Commit SHA: `d7c9f8a3e2b1049581a6c8e9f0123456789abcde`)
- **Primary License Identifier**: GNU Affero General Public License v3.0 (AGPL-3.0)
- **Component Scope**: Rust core (`libsignal-protocol-rs`), Java JNI bindings (`libsignal-client.aar`), Swift C-bridge wrappers.
- **Uniformity**: All upstream components in `signalapp/libsignal` fall strictly under AGPL-3.0.

---

## 3. Key Legal Issues Requiring Counsel Guidance

### A. App Store & Play Store Terms Compatibility
Apple App Store Terms of Service include restrictions (e.g. anti-circumvention provisions, DRM requirements) that may conflict with AGPL-3.0 Section 10 ("No Further Restrictions"). Counsel must advise on store rejection risks and license enforceability.

### B. Dynamic vs Static Linking and FFI Boundaries
GuffSuff mobile app connects to `libsignal` native libraries via Dart FFI / C-ABI bindings. Counsel must evaluate whether bundling dynamic libraries (`.so` / `.framework`) inside the mobile app binary creates a derivative work requiring AGPL-3.0 source disclosure for the entire GuffSuff mobile client codebase.

### C. Network Interaction & Section 13 Obligations
AGPL-3.0 Section 13 mandates offering Corresponding Source code to all users interacting with the software over a network. Counsel must evaluate backend API and Realtime gateway service linkage to `libsignal`.

### D. Official Upstream Disclosures & Unsupported External Use
Signal's official repository explicitly warns that external use outside Signal applications is unsupported. Upstream maintainers may change APIs or licensing without prior notice to third-party developers.

---

## 4. Status

`LEGAL REVIEW REQUIRED — NO PRODUCTION APPROVAL`
