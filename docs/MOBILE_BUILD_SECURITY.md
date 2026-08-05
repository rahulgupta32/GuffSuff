# GuffSuff Mobile Build Security Policy

> **Document Status**: Phase 3 Development Platform Baseline

---

## 1. Environment & Flavor Isolation

- **Build Flavors**: Flutter client supports `development`, `staging`, and `production` build flavors (`ADR-040`).
- **Development Watermark**: Development builds display a mandatory status banner (`Development build — not for production use`).
- **Production Build Hardening**: Production flavor builds fail if development endpoints, mock crypto flags, or un-obscured logging hooks are detected.
- **Signing Keys**: Production release signing keys are managed strictly via cloud HSM / key store services. Zero private keys are stored in source code.
