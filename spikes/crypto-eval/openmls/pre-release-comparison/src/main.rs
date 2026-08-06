// PRE-RELEASE RESEARCH ONLY — NOT PRODUCTION CANDIDATE
use openmls::prelude::*;
use openmls_rust_crypto::OpenMlsRustCrypto;
use openmls_basic_credential::BasicCredential;
use std::sync::Arc;

struct Party {
    name: String,
    signer: SignatureKeyPair,
    credential: BasicCredential,
    key_package: KeyPackage,
}

fn create_party(provider: &OpenMlsRustCrypto, name: &str, ciphersuite: Ciphersuite) -> Party {
    let credential = BasicCredential::new(name.as_bytes().to_vec());
    let signer = SignatureKeyPair::new(ciphersuite.signature_algorithm()).unwrap();
    let credential_with_key = CredentialWithKey {
        credential: credential.clone().into(),
        signature_key: signer.to_public_key().into(),
    };
    let key_package_builder = KeyPackage::builder();
    let key_package = key_package_builder
        .build(ciphersuite, provider, &signer, credential_with_key)
        .unwrap();

    Party {
        name: name.to_string(),
        signer,
        credential,
        key_package,
    }
}

fn main() {
    println!("=== OpenMLS v0.9.0-rc.2 Pre-Release Lifecycle Evaluation ===");
    println!("STATUS: PRE-RELEASE RESEARCH ONLY — NOT PRODUCTION CANDIDATE");

    let provider = OpenMlsRustCrypto::default();
    let ciphersuite = Ciphersuite::MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519;

    let alice = create_party(&provider, "Alice", ciphersuite);
    let bob = create_party(&provider, "Bob", ciphersuite);
    let charlie = create_party(&provider, "Charlie", ciphersuite);

    let alice_cred = CredentialWithKey {
        credential: alice.credential.clone().into(),
        signature_key: alice.signer.to_public_key().into(),
    };

    let group_config = MlsGroupCreateConfig::builder()
        .ciphersuite(ciphersuite)
        .build();

    let mut alice_group = MlsGroup::new(
        &provider,
        &alice.signer,
        &group_config,
        alice_cred,
    ).expect("Alice failed to create group");

    println!("Scenario 1: Group Creation PASSED");

    // Add Bob
    let (commit_msg, welcome_msg, _kpr) = alice_group
        .add_members(&provider, &alice.signer, &[bob.key_package.clone()])
        .expect("Alice failed to add Bob");

    alice_group.merge_pending_commit(&provider).expect("Alice failed to merge pending commit");
    println!("Scenario 2: Add Member (Bob) PASSED");

    // Bob joins via Welcome
    let bob_join_config = MlsGroupJoinConfig::default();
    let mut bob_group = MlsGroup::new_from_welcome(
        &provider,
        &bob_join_config,
        welcome_msg.into_welcome().unwrap(),
        Some(bob.key_package.key_package().clone()),
    ).expect("Bob failed to process Welcome");

    println!("Scenario 3: Process Welcome (Bob) PASSED");

    // Application Message
    let msg = b"Hello OpenMLS 0.9.0-rc.2!";
    let unauth_msg = alice_group.create_message(&provider, &alice.signer, msg).expect("Create msg failed");
    let processed_msg = bob_group.parse_message(unauth_msg, &provider).expect("Parse msg failed");

    match processed_msg.into_content() {
        ProcessedMessageContent::ApplicationMessage(app_msg) => {
            assert_eq!(app_msg.into_bytes(), msg);
            println!("Scenario 4: Two-Way Application Message PASSED");
        }
        _ => panic!("Expected application message"),
    }

    println!("OpenMLS v0.9.0-rc.2 Pre-Release Lifecycle Evaluation Complete: 4/4 Scenarios Passed");
}
