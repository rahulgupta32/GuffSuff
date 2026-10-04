# ADR-063: Open-source direct messaging provider direction

- Status: Direction selected; production integration not complete
- Date: 2026-10-04
- Decision: The owner selected an open-source mobile application. Evaluate official signalapp/libsignal for direct messaging through native Android/Swift bindings; do not substitute the development boundary provider.
- Candidate reviewed: v0.104.0, published 2026-10-02. This is a review baseline, not an installed dependency or a claim of production approval.

## Verified upstream requirements

The official README explicitly says use outside Signal is unsupported and its bindings may change incompatibly. Java/Android builds use JDK 21. Current Java client dependencies include modern Kotlin coroutine/serialization libraries. Published Android integration needs both libsignal-android and libsignal-client from Signal's own Maven repository, rather than assuming a current Maven Central artifact exists. The library is AGPLv3; source distribution and notices must be resolved before release. Selecting open source does not automatically complete that packaging work.

The current PreKeyBundle constructor requires a signed Kyber/KEM prekey in addition to the identity, classical signed prekey and optional classical one-time prekey. The initial migration 007 and API carry only classical material; migration 008 adds signed KEM public fields in bundle version 2. This remains a tested distribution foundation; native key parsing/signature verification and stable numeric device-address mapping are still missing from complete v0.104.0 integration. Do not claim this API can already establish a modern libsignal session, invent missing KEM keys or select an obsolete release merely to bypass the requirement.

## Required implementation order

1. Extend versioned public bundles and claims for the provider-required signed KEM material, device address mapping and verified rotation. Preserve immutable retry snapshots through rotation. Validate client signature authenticity and identity continuity with the library.
2. Build an Android native adapter against exact pinned artifacts with dependency verification, JDK/toolchain compatibility checks and real JNI cryptographic tests. The existing Flutter 3.29.2 build baseline must be explicitly revalidated after any upgrades. Implement the corresponding Swift adapter in a committed iOS project.
3. Persist private identities, prekeys, peer identity trust and ratchet/session records in a protected account/device store. Commit session mutation and outgoing ciphertext or incoming plaintext/history atomically. Prevent concurrent operations against one session, unsafe backup restoration and key reuse.
4. Change transport to address each recipient device with its own ciphertext. The present shared opaque payload fan-out cannot stand in for separate per-device Signal sessions. Establish stable retry batches and recipient/device authorization.
5. Connect the provider to the composer and receive/history coordinator; add explicit key-change and delivery failure UI. Test two independent devices, tampering, reordered/duplicate messages, offline retries, crash recovery, revocation and reinstall before enabling messaging in release.

The current composer remains disabled. No private keys, SMS, tester messages or native production dependency have been introduced by this direction decision.

## Sources

- https://github.com/signalapp/libsignal/releases/tag/v0.104.0
- https://github.com/signalapp/libsignal/blob/v0.104.0/README.md
- https://github.com/signalapp/libsignal/blob/v0.104.0/LICENSE
- https://github.com/signalapp/libsignal/blob/v0.104.0/java/android/build.gradle
- https://github.com/signalapp/libsignal/blob/v0.104.0/java/client/build.gradle
- https://github.com/signalapp/libsignal/blob/v0.104.0/java/shared/java/org/signal/libsignal/protocol/state/PreKeyBundle.kt
