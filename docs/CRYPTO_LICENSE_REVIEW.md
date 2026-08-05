# Cryptographic Library License Review & Legal Compliance

> **Document Status**: Legal & Open Source Compliance Assessment (Detailed AGPL Analysis)

---

## 1. Comprehensive `libsignal` AGPL-3.0 Compliance Analysis

- **Repository Identifier & License Text**: `GNU Affero General Public License v3.0` (AGPL-3.0). All sub-components in `libsignal` fall under AGPL-3.0.
- **Unsupported External-Use Warning**: Signal official repository documentation explicitly notes that `libsignal` is published for transparency and Signal client use; external consumption is unsupported.
- **Mobile Application Distribution Implications**: Packaging AGPL-3.0 native shared libraries (`.so` / `.framework`) inside a mobile client binary may trigger requirements to provide complete corresponding source code under AGPL-3.0 for the entire mobile app.
- **Static vs Dynamic Linking**: Static linking creates a single combined binary subject to AGPL-3.0. Dynamic linking across FFI boundaries remains subject to legal interpretation under AGPL-3.0 section 13 (Remote Network Interaction).
- **Source Distribution & Corresponding Source Obligations**: Distributing an AGPL-3.0 application or offering it over a network requires conveying the complete Corresponding Source code of all modifications and surrounding code.
- **App Store & Play Store Terms**: Apple App Store Terms of Service contain restrictions (e.g. DRM / anti-circumvention provisions) that may conflict with AGPL-3.0 section 10 (No Further Restrictions), creating potential store rejection risks.
- **Backend / Network Service Implications**: Operating a backend service that uses or interfaces with AGPL-3.0 code triggers network copyleft obligations to offer source code downloads to all network users.
- **Export Control & Third-Party Notices**: Upstream cryptographic notices must be maintained verbatim in application attribution files.
- **Commercial Approval Status**: `libsignal` is **NOT commercially approved** for GuffSuff production integration without explicit written legal review by qualified IP counsel.

---

## 2. OpenMLS & Supporting Primitive Licensing

- **OpenMLS**: Dual MIT / Apache-2.0 License. Permissive, low legal risk for mobile and server compilation.
- **`libsodium`**: ISC License. Permissive BSD-style license, low legal risk for supporting primitive utilities.
