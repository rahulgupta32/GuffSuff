# GuffSuff Secure Coding Standards & Guidelines

> **Document Status**: Phase 2 Security Architecture Baseline  
> **Citations**: OWASP ASVS v4.0.3, OWASP MASVS v2.0.0, NIST SP 800-218 (SSDF)

---

## 1. Core Secure Coding Principles

1. **Defense in Depth**: Rely on layered security controls rather than single point-of-failure assumptions.
2. **Zero-Trust Input Validation**: Treat all client inputs, API payloads, WebSocket frames, and external headers as untrusted. Validate using strict schema schemas (Zod DTOs).
3. **Least Privilege**: Microservices and database connection pools operate with minimal required SQL privileges.
4. **Fail Securely**: Systems MUST fail closed. Exceptions must not bypass authentication, rate-limiting, or authorization checks.
5. **No Custom Cryptography**: Developers MUST NOT implement cryptographic algorithms, custom ratchets, or custom hash schemes. All crypto operations go through `packages/crypto-adapter`.

---

## 2. Language-Specific Guidelines

### TypeScript / Node.js / NestJS Rules

- **No `eval()` or Dynamic Code Execution**: `eval`, `Function()`, and `vm.runInContext` are strictly prohibited.
- **SQL Injection Prevention**: Parameterize all queries using ORM/Kysely parameter bindings. Raw string concatenation in SQL queries is forbidden.
- **Path Traversal Protection**: Validate and sanitize all file paths using `path.resolve` and verify paths remain within designated target directories.
- **Strict Error Handling**: Do not expose internal stack traces or database error messages in API HTTP responses.

### Dart / Flutter Rules

- **Secure Key Storage**: Store keys exclusively in hardware-backed storage via `flutter_secure_storage` (Keychain/Keystore). Never hardcode secrets in `.dart` source code.
- **Input Sanitization**: Escape user text rendering to prevent UI injection attacks.
- **SQLCipher Usage**: Ensure SQLite operations use encrypted drivers with keys derived from secure storage.
