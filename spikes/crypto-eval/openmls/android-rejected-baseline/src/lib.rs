// REJECTED DEPENDENCY BASELINE — COMPATIBILITY RESEARCH ONLY
// NOTE: THIS BINARY IS A REJECTED RESEARCH CANDIDATE AND MUST NOT BE USED IN PRODUCTION.

use openmls::prelude::*;
use openmls_rust_crypto::OpenMlsRustCrypto;

#[no_mangle]
pub extern "C" fn openmls_rejected_research_init() -> i32 {
    let provider = OpenMlsRustCrypto::default();
    let _cs = Ciphersuite::MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519;
    let _group_config = MlsGroupCreateConfig::builder()
        .ciphersuite(_cs)
        .build();
    0
}
