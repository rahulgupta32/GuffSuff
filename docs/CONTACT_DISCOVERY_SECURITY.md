# GuffSuff Privacy-Preserving Contact Discovery Architecture

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Cryptographic Reality Warning**: Simple hashing (SHA-256) of phone numbers IS NOT cryptographically private contact discovery because the numerical search space (+977 phone numbers) is small (~10 million possibilities) and vulnerable to dictionary enumeration.

---

## 1. Staged Contact Discovery Strategy

### Stage A: Privacy-Minimized Salted Hashing (MVP Baseline)
- **Local Normalization**: Phone numbers normalized locally on mobile device to E.164.
- **Client-Side Salting**: Hashes computed as `HMAC-SHA256(phone_e164, daily_server_salt)`.
- **Zero Raw Uploads**: Raw address book numbers are NEVER transmitted to the server.
- **Immediate Hash Ephemerality**: Candidate hashes submitted via `POST /api/v1/contacts/discover` are matched in-memory against `phone_identities` hashes and discarded immediately.
- **Anti-Enumeration Rate Limits**: Max 50 contact discovery queries per user per hour (`SEC-API-001`).

### Stage B: Cryptographic Privacy Evaluation (Post-MVP Candidate)
- **Private Set Intersection (PSI)**: Evaluating PSI protocols (e.g. EC-OPRF / Oblivious Pseudorandom Function) where server learns zero information about non-matching contacts and client learns zero information about non-contact users.
- **Status**: Stage B is `UNDER EVALUATION` during Phase 2.
