// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import javax.crypto.Cipher
import javax.crypto.SecretKey
import org.junit.After
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.signal.libsignal.protocol.SessionBuilder
import org.signal.libsignal.protocol.SessionCipher
import org.signal.libsignal.protocol.message.PreKeySignalMessage
import org.signal.libsignal.protocol.message.SignalMessage
import org.signal.libsignal.protocol.state.PreKeyBundle
import org.signal.libsignal.protocol.state.PreKeyRecord
import org.signal.libsignal.protocol.state.SignedPreKeyRecord
import org.signal.libsignal.protocol.state.KyberPreKeyRecord

/** Actual AndroidKeyStore/filesystem tests. Every scope is an isolated generated fixture. */
@RunWith(AndroidJUnit4::class)
class DeviceIdentityStoreTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val scopes = mutableListOf<Pair<String, String>>()

    private fun scope(): Pair<String, String> =
        (UUID.randomUUID().toString() to UUID.randomUUID().toString()).also { scopes.add(it) }

    private fun hash(scope: Pair<String, String>): String = MessageDigest.getInstance("SHA-256")
        .digest("${scope.first.lowercase()}/${scope.second.lowercase()}".toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it.toInt() and 255) }

    private fun record(scope: Pair<String, String>) =
        File(context.noBackupFilesDir, "libsignal-identities/${hash(scope)}.bin")

    private fun alias(scope: Pair<String, String>) = "guffsuff.libsignal.identity.${hash(scope)}"

    private fun initialize(scope: Pair<String, String>) =
        DeviceIdentityStore(context).initialize(scope.first, scope.second)

    @After fun removeOnlyGeneratedFixtures() {
        val keys = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        for (scope in scopes) {
            val file = record(scope)
            file.delete()
            File(file.path + ".bak").delete()
            File(file.path + ".new").delete()
            keys.deleteEntry(alias(scope))
        }
    }

    @Test fun restoresSameIdentityAcrossStoreInstancesAndUuidCase() {
        val scope = scope()
        val original = initialize(scope)
        assertEquals(original, initialize(scope))
        assertEquals(original, initialize(scope.first.uppercase() to scope.second.uppercase()))
        assertEquals(false, original["supportsDirectMessaging"])
        assertEquals(setOf("providerId", "providerVersion", "identityPublicKeyBase64", "registrationId", "supportsDirectMessaging"), original.keys)
        assertTrue(record(scope).isFile)
        val wrappingKey = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.getKey(alias(scope), null)
        assertNull("Wrapping key must not be exportable", wrappingKey.encoded)
    }

    @Test fun independentAccountAndDeviceScopesDoNotShareIdentity() {
        val first = scope()
        val otherAccount = (UUID.randomUUID().toString() to first.second).also { scopes.add(it) }
        val otherDevice = (first.first to UUID.randomUUID().toString()).also { scopes.add(it) }
        val publicKey = initialize(first)["identityPublicKeyBase64"]
        assertNotEquals(publicKey, initialize(otherAccount)["identityPublicKeyBase64"])
        assertNotEquals(publicKey, initialize(otherDevice)["identityPublicKeyBase64"])
    }

    @Test fun concurrentInitializationConvergesOnOneIdentity() {
        val scope = scope()
        val executor = Executors.newFixedThreadPool(8)
        try {
            val futures = executor.invokeAll((1..8).map { Callable { initialize(scope) } }, 30, TimeUnit.SECONDS)
            val results = futures.map { it.get(5, TimeUnit.SECONDS) }
            assertTrue(results.all { it == results.first() })
            assertEquals(results.first(), initialize(scope))
        } finally { executor.shutdownNow() }
    }

    @Test fun tamperedCiphertextFailsWithoutReplacingIdentity() {
        val scope = scope()
        val original = initialize(scope)
        val file = record(scope)
        val valid = file.readBytes()
        val tampered = valid.copyOf().apply { this[lastIndex] = (this[lastIndex].toInt() xor 1).toByte() }
        file.writeBytes(tampered)
        assertThrows(Exception::class.java) { initialize(scope) }
        assertArrayEquals(tampered, file.readBytes())
        file.writeBytes(valid)
        assertEquals(original, initialize(scope))
    }

    @Test fun missingWrappingKeyFailsWithoutReplacingRecord() {
        val scope = scope()
        initialize(scope)
        val bytes = record(scope).readBytes()
        KeyStore.getInstance("AndroidKeyStore").apply { load(null); deleteEntry(alias(scope)) }
        assertThrows(IllegalStateException::class.java) { initialize(scope) }
        assertArrayEquals(bytes, record(scope).readBytes())
    }

    @Test fun missingRecordFailsWithoutReplacingWrappingKey() {
        val scope = scope()
        initialize(scope)
        assertTrue(record(scope).delete())
        assertThrows(IllegalStateException::class.java) { initialize(scope) }
        assertFalse(record(scope).exists())
        assertTrue(KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.containsAlias(alias(scope)))
    }

    @Test fun interruptedAtomicFileBackupRestoresOriginalIdentity() {
        val scope = scope()
        val original = initialize(scope)
        val file = record(scope)
        assertTrue(file.renameTo(File(file.path + ".bak")))
        file.writeBytes(byteArrayOf(1, 2, 3))
        assertEquals(original, initialize(scope))
        assertFalse(File(file.path + ".bak").exists())
    }

    @Test fun invalidScopeFailsBeforeCreatingStorage() {
        assertThrows(IllegalArgumentException::class.java) {
            DeviceIdentityStore(context).initialize("../invalid", UUID.randomUUID().toString())
        }
    }

    @Test fun signedPublicBundleRestoresExactlyWithoutReplacingIdentity() {
        val scope = scope()
        val originalIdentity = initialize(scope)
        val original = DeviceIdentityStore(context).initializePreKeys(scope.first, scope.second)
        val restored = DeviceIdentityStore(context).initializePreKeys(scope.first, scope.second)
        assertEquals(original, restored)
        assertEquals(originalIdentity["identityPublicKeyBase64"], restored["identityPublicKeyBase64"])
        assertEquals(false, restored["supportsDirectMessaging"])
        val bundle = restored["bundle"] as Map<*, *>
        assertEquals(2, bundle["protocolVersion"])
        assertEquals(100, (bundle["oneTimePrekeys"] as List<*>).size)
        assertEquals(setOf("protocolVersion", "registrationId", "identityPublicKeyBase64", "signedPrekeyId",
            "signedPrekeyPublicBase64", "signedPrekeySignatureBase64", "kemPrekeyId", "kemPrekeyPublicBase64",
            "kemPrekeySignatureBase64", "expiresAt", "oneTimePrekeys"), bundle.keys)
    }

    @Test fun failedStagedMutationLeavesEntireEncryptedStateUnchanged() {
        val scope = scope()
        val store = DeviceIdentityStore(context)
        val original = store.initializePreKeys(scope.first, scope.second)
        val before = record(scope).readBytes()
        assertThrows(IllegalStateException::class.java) {
            store.withState(scope.first, scope.second) { state ->
                state.preKeys.remove(1)
                error("Injected operation failure")
            }
        }
        assertArrayEquals(before, record(scope).readBytes())
        assertEquals(original, store.initializePreKeys(scope.first, scope.second))
    }

    @Test fun encryptedLegacyRecordMigratesWithoutRegeneratingIdentity() {
        val scope = scope()
        val store = DeviceIdentityStore(context)
        val original = initialize(scope)
        val legacy = store.withState(scope.first, scope.second) { it.identity.encode() }
        try {
            val key = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.getKey(alias(scope), null) as SecretKey
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key)
            cipher.updateAAD("guffsuff/libsignal/identity/v1/${scope.first}/${scope.second}".toByteArray(Charsets.UTF_8))
            record(scope).writeBytes(byteArrayOf(1) + cipher.iv + cipher.doFinal(legacy))
            val upgraded = DeviceIdentityStore(context).initializePreKeys(scope.first, scope.second)
            assertEquals(original["identityPublicKeyBase64"], upgraded["identityPublicKeyBase64"])
            assertEquals(original["registrationId"], upgraded["registrationId"])
            assertEquals(upgraded, DeviceIdentityStore(context).initializePreKeys(scope.first, scope.second))
        } finally { legacy.fill(0) }
    }

    @Test fun realEncryptedExchangeAndReplayRejectionSurviveNewStoreInstances() {
        val alice = scope(); val bob = scope()
        fun <T> transaction(scope: Pair<String, String>, operation: (DeviceKeyState) -> T): T =
            DeviceIdentityStore(context).withState(scope.first, scope.second, operation)
        DeviceIdentityStore(context).initializePreKeys(alice.first, alice.second)
        DeviceIdentityStore(context).initializePreKeys(bob.first, bob.second)
        val aliceAddress = DeviceProtocolStore.deviceAddress(alice.second)
        val bobAddress = DeviceProtocolStore.deviceAddress(bob.second)
        val bundle = transaction(bob) { state ->
            val signed = SignedPreKeyRecord(state.signedPreKey!!); val kem = KyberPreKeyRecord(state.kemPreKey!!)
            val prekey = PreKeyRecord(state.preKeys.getValue(1))
            PreKeyBundle(state.identity.registrationId, 1, prekey.id, prekey.keyPair.publicKey,
                signed.id, signed.keyPair.publicKey, signed.signature, state.identity.pair.publicKey,
                kem.id, kem.keyPair.publicKey, kem.signature)
        }
        transaction(alice) { SessionBuilder(DeviceProtocolStore(it), bobAddress, aliceAddress).process(bundle) }
        val message = "गफसफ Android protected session".toByteArray(Charsets.UTF_8)
        val outgoingId = UUID.randomUUID().toString(); val incomingId = UUID.randomUUID().toString()
        val intent = "fixture-routing/alice/bob/first".toByteArray() + message
        val beforeEncryptFailure = record(alice).readBytes()
        assertThrows(IllegalStateException::class.java) {
            transaction(alice) { state ->
                NativeMessageJournal(state).outgoing(outgoingId, intent) {
                    SessionCipher(DeviceProtocolStore(state), aliceAddress, bobAddress).encrypt(message)
                    error("Injected outbox failure")
                }
            }
        }
        assertArrayEquals(beforeEncryptFailure, record(alice).readBytes())
        val encrypted = transaction(alice) { state ->
            NativeMessageJournal(state).outgoing(outgoingId, intent) {
                SessionCipher(DeviceProtocolStore(state), aliceAddress, bobAddress).encrypt(message).serialize() to message
            }.ciphertext()
        }
        // Fresh encrypted storage load: retry must leave every session byte unchanged.
        val beforeRetry = transaction(alice) { it.sessions.mapValues { entry -> entry.value.copyOf() } }
        assertArrayEquals(encrypted, transaction(alice) { state ->
            NativeMessageJournal(state).outgoing(outgoingId, intent) { error("Retry advanced ratchet") }.ciphertext()
        })
        transaction(alice) { state -> for ((key, bytes) in beforeRetry) assertArrayEquals(bytes, state.sessions.getValue(key)) }
        // Decryption mutates prekeys/ratchet; failure before persistence must discard all of it.
        val beforeFailure = record(bob).readBytes()
        assertThrows(IllegalStateException::class.java) {
            transaction(bob) { state ->
                NativeMessageJournal(state).incoming(incomingId, encrypted) {
                    SessionCipher(DeviceProtocolStore(state), bobAddress, aliceAddress).decrypt(PreKeySignalMessage(encrypted))
                    error("Injected history failure")
                }
            }
        }
        assertArrayEquals(beforeFailure, record(bob).readBytes())
        assertArrayEquals(message, transaction(bob) { state ->
            NativeMessageJournal(state).incoming(incomingId, encrypted) {
                SessionCipher(DeviceProtocolStore(state), bobAddress, aliceAddress).decrypt(PreKeySignalMessage(encrypted))
            }
        })
        assertArrayEquals(message, transaction(bob) { state ->
            NativeMessageJournal(state).incoming(incomingId, encrypted) { error("Duplicate advanced ratchet") }
        })
        transaction(alice) { NativeMessageJournal(it).markAccepted(outgoingId, intent) }
        transaction(alice) { state ->
            assertTrue(NativeMessageJournal(state).pending().isEmpty())
            assertArrayEquals(encrypted, NativeMessageJournal(state).outgoing(outgoingId, intent) { error("Accepted retry") }.ciphertext())
        }
        val beforeReplay = record(bob).readBytes()
        assertThrows(Exception::class.java) {
            transaction(bob) { SessionCipher(DeviceProtocolStore(it), bobAddress, aliceAddress).decrypt(PreKeySignalMessage(encrypted)) }
        }
        assertArrayEquals(beforeReplay, record(bob).readBytes())
        transaction(bob) {
            assertFalse(DeviceProtocolStore(it).containsPreKey(1))
            assertEquals(1, it.usedKemBaseKeys.size)
        }
        val reply = "restored reply".toByteArray(Charsets.UTF_8)
        val encryptedReply = transaction(bob) { SessionCipher(DeviceProtocolStore(it), bobAddress, aliceAddress).encrypt(reply).serialize() }
        assertArrayEquals(reply, transaction(alice) {
            SessionCipher(DeviceProtocolStore(it), aliceAddress, bobAddress).decrypt(SignalMessage(encryptedReply))
        })
    }

    @Test fun serializationCapacityFailureRollsBackPrekeyAndJournalMutations() {
        val scope = scope(); val store = DeviceIdentityStore(context)
        store.initializePreKeys(scope.first, scope.second)
        val before = record(scope).readBytes()
        assertThrows(IllegalArgumentException::class.java) {
            store.withState(scope.first, scope.second) { state ->
                state.preKeys.remove(1)
                repeat(20) {
                    NativeMessageJournal(state).outgoing(UUID.randomUUID().toString(), byteArrayOf(1)) {
                        ByteArray(NativeMessageJournal.MAX_BATCH) to byteArrayOf(1)
                    }
                }
            }
        }
        assertArrayEquals(before, record(scope).readBytes())
        store.withState(scope.first, scope.second) {
            assertTrue(it.preKeys.containsKey(1))
            assertTrue(it.outbox.isEmpty())
        }
    }

    @Test fun expiredBundleRequiresRotationWithoutExtendingOrReplacingKeys() {
        val scope = scope(); val store = DeviceIdentityStore(context)
        store.withState(scope.first, scope.second) { it.initializePreKeys(System.currentTimeMillis() - DeviceKeyState.BUNDLE_LIFETIME - 1000) }
        val before = record(scope).readBytes()
        assertThrows(IllegalStateException::class.java) { store.initializePreKeys(scope.first, scope.second) }
        assertArrayEquals(before, record(scope).readBytes())
    }
}
