# Cryptographic Candidate Comparison Matrix & Artifact Release Inventory

> **Document Status**: Machine-Verified Candidate Artifact Matrix

---

## 1. Multi-Dimensional `libsignal` Artifact Matrix

| Artifact Dimension | Candidate Version `v0.60.0` | Candidate Version `v0.99.4` | Evaluation Notes |
| :--- | :--- | :--- | :--- |
| **GitHub Source Archive** | `PUBLIC OFFICIAL ARTIFACT AVAILABLE` | `PUBLIC OFFICIAL ARTIFACT AVAILABLE` | Source `.tar.gz` and `.zip` archives published on GitHub. |
| **GitHub Release Assets** | `PUBLIC OFFICIAL ARTIFACT AVAILABLE` | `PUBLIC OFFICIAL ARTIFACT AVAILABLE` | `.sym` debug-symbol packages uploaded to GitHub release page. |
| **Java Artifact (Maven Central)** | `PUBLIC OFFICIAL ARTIFACT AVAILABLE` (`org.signal:libsignal-client:0.60.0`, `jar`) | `NOT PUBLISHED` | Maven Central Java client binding missing for v0.99.4. |
| **Android Artifact (Maven Central)** | `PUBLIC OFFICIAL ARTIFACT AVAILABLE` (`org.signal:libsignal-android:0.60.0`, `aar`) | `NOT PUBLISHED` | Maven Central Android AAR missing for v0.99.4. |
| **Swift / iOS Build Artifact** | `PUBLIC SOURCE BUILD AVAILABLE` | `PUBLIC SOURCE BUILD AVAILABLE` | SPM package / Swift C-bridge requires local Xcode build. |
| **TypeScript / Node Artifact** | `INTERNAL OR SIGNAL-SPECIFIC ARTIFACT` (`@signalapp/libsignal-client`) | `INTERNAL OR SIGNAL-SPECIFIC ARTIFACT` | Published to private npm registry / GitHub packages. |
| **Rust Crates.io Crate** | `NOT PUBLISHED` | `NOT PUBLISHED` | `libsignal-protocol-rs` is not published on crates.io. |
| **Debug-Symbol Packages** | `PUBLIC OFFICIAL ARTIFACT AVAILABLE` (`.sym` files) | `PUBLIC OFFICIAL ARTIFACT AVAILABLE` (`.sym` files) | Debug symbols hosted on GitHub releases. |

---

## 2. Selection & Governance Decision

- **`libsignal` `v0.60.0`**: Classified as `Historical comparison baseline — not proposed for production integration`. Last version with public Maven Central Android AAR.
- **`libsignal` `v0.99.4`**: Source build available, but lacks public Maven Central Android binaries. Requires custom CI build pipeline if evaluated for production.
- **OpenMLS `openmls-v0.8.1`**: Classified as `Proposed Spike Evaluation Candidate` (`PUBLIC OFFICIAL ARTIFACT AVAILABLE` on Crates.io).
