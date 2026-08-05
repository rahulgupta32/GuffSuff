# Cryptographic Library License Review

> **Document Status**: Legal & Open Source Compliance Assessment

---

## License Comparison Matrix

| Provider / Library | Primary License | Server Linking Implications | Mobile App Linking Implications | Copyleft Virality Risk |
| :--- | :--- | :--- | :--- | :--- |
| **`libsignal`** | AGPL-3.0 | High (Network use triggers source disclosure requirement if modified) | High (Requires clear isolation or open-sourcing client app under AGPL) | **CRITICAL** |
| **OpenMLS** | MIT | Low (Permissive) | Low (Permissive) | None |
| **`libsodium`** | ISC | Low (Permissive) | Low (Permissive) | None |

---

## Recommendations
1. `libsignal` requires explicit legal authorization prior to integration due to AGPL-3.0 copyleft obligations.
2. OpenMLS and `libsodium` pose minimal legal risk under standard MIT / ISC licensing.
