## Summary of Changes

<!-- Provide a concise description of the changes introduced in this PR -->

## Type of Change

- [ ] `feat`: New feature
- [ ] `fix`: Bug fix
- [ ] `security`: Security update / crypto fix
- [ ] `docs`: Documentation update
- [ ] `refactor`: Code refactor
- [ ] `test`: Unit / integration test updates
- [ ] `chore`: Housekeeping / infrastructure

## Security & Privacy Compliance Checklist

- [ ] **No Secrets**: Confirmed no API keys, credentials, or private keys are in code or git history.
- [ ] **Zero Server Plaintext**: Confirmed no message plaintext or sensitive media content is logged or stored server-side.
- [ ] **E.164 / Nepal Number Handling**: Phone numbers strictly normalized to E.164 format (+977...).
- [ ] **Devanagari Safety**: String processing handles multi-byte Devanagari characters cleanly.
- [ ] **OWASP Compliance**: Verified against OWASP MASVS / ASVS rules.

## Testing Performed

- [ ] Unit tests pass locally
- [ ] Integration tests pass
- [ ] Mobile smoke test completed (if applicable)

## Linked Issue / Architecture Decision

Closes #<!-- Issue number -->
Refers to ADR: `docs/adr/`<!-- ADR filename if applicable -->
