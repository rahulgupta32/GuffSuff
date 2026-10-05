// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.util.UUID
import org.junit.Assert.*
import org.junit.Test
import org.signal.libsignal.protocol.*
import org.signal.libsignal.protocol.ecc.ECKeyPair
import org.signal.libsignal.protocol.message.PreKeySignalMessage
import org.signal.libsignal.protocol.message.SignalMessage
import org.signal.libsignal.protocol.state.*

class DeviceKeyStateTest {
    private fun state() = DeviceKeyState(IdentityMaterial.create()).apply { initializePreKeys(System.currentTimeMillis()) }
    private fun restored(state: DeviceKeyState): DeviceKeyState {
        val bytes = state.encode()
        try { return DeviceKeyState.decode(bytes) } finally { bytes.fill(0) }
    }
    private fun address() = DeviceProtocolStore.deviceAddress(UUID.randomUUID().toString())
    private fun bundle(state: DeviceKeyState, corruptSigned: Boolean = false, corruptKem: Boolean = false): PreKeyBundle {
        val signed = SignedPreKeyRecord(state.signedPreKey!!)
        val kem = KyberPreKeyRecord(state.kemPreKey!!)
        val prekey = PreKeyRecord(state.preKeys.getValue(1))
        val signature = signed.signature.apply { if (corruptSigned) this[0] = (this[0].toInt() xor 1).toByte() }
        val kemSignature = kem.signature.apply { if (corruptKem) this[0] = (this[0].toInt() xor 1).toByte() }
        return PreKeyBundle(state.identity.registrationId, 1, prekey.id, prekey.keyPair.publicKey,
            signed.id, signed.keyPair.publicKey, signature, state.identity.pair.publicKey,
            kem.id, kem.keyPair.publicKey, kemSignature)
    }

    @Test fun legacyRecordPreservesOriginalIdentityWhenUpgraded() {
        val identity = IdentityMaterial.create()
        val legacy = identity.encode()
        try {
            val upgraded = restored(DeviceKeyState.decode(legacy))
            assertEquals(identity.registrationId, upgraded.identity.registrationId)
            assertArrayEquals(identity.pair.publicKey.serialize(), upgraded.identity.pair.publicKey.serialize())
            assertNull(upgraded.signedPreKey)
        } finally { legacy.fill(0) }
    }

    @Test fun generatedPrekeysAndSignaturesSurviveRestoration() {
        val original = state()
        val copy = restored(original)
        assertEquals(100, copy.preKeys.size)
        assertEquals(100, copy.preKeys.values.map { PreKeyRecord(it).keyPair.publicKey.serialize().toList() }.toSet().size)
        val signed = SignedPreKeyRecord(copy.signedPreKey!!)
        val kem = KyberPreKeyRecord(copy.kemPreKey!!)
        assertTrue(copy.identity.pair.publicKey.publicKey.verifySignature(signed.keyPair.publicKey.serialize(), signed.signature))
        assertTrue(copy.identity.pair.publicKey.publicKey.verifySignature(kem.keyPair.publicKey.serialize(), kem.signature))
        assertTrue(original.signedPreKey!!.contentEquals(copy.signedPreKey!!))
        assertTrue(original.kemPreKey!!.contentEquals(copy.kemPreKey!!))
        assertEquals(original.bundleExpiresAt(), copy.bundleExpiresAt())
    }

    @Test fun realTwoPartyExchangeSurvivesRestorationBetweenEveryStage() {
        var alice = restored(state())
        var bob = restored(state())
        val aliceAddress = address(); val bobAddress = address()
        SessionBuilder(DeviceProtocolStore(alice), bobAddress, aliceAddress).process(bundle(bob))
        alice = restored(alice)
        val plaintext = "गफसफ वास्तविक encrypted session".toByteArray(Charsets.UTF_8)
        val encrypted = SessionCipher(DeviceProtocolStore(alice), aliceAddress, bobAddress).encrypt(plaintext).serialize()
        alice = restored(alice)
        assertArrayEquals(plaintext, SessionCipher(DeviceProtocolStore(bob), bobAddress, aliceAddress).decrypt(PreKeySignalMessage(encrypted)))
        bob = restored(bob)
        assertFalse(DeviceProtocolStore(bob).containsPreKey(1))
        assertEquals(1, bob.usedKemBaseKeys.size)
        val reply = "प्रतिउत्तर".toByteArray(Charsets.UTF_8)
        val encryptedReply = SessionCipher(DeviceProtocolStore(bob), bobAddress, aliceAddress).encrypt(reply).serialize()
        bob = restored(bob)
        assertArrayEquals(reply, SessionCipher(DeviceProtocolStore(alice), aliceAddress, bobAddress).decrypt(SignalMessage(encryptedReply)))
        assertTrue(DeviceProtocolStore(restored(alice)).containsSession(bobAddress))
        assertTrue(DeviceProtocolStore(bob).containsSession(aliceAddress))
    }

    @Test fun nativeSessionBuilderRejectsTamperedClassicalAndKemSignatures() {
        val bob = state()
        for (corruptSigned in listOf(true, false)) {
            val alice = state()
            assertThrows(InvalidKeyException::class.java) {
                SessionBuilder(DeviceProtocolStore(alice), address(), address()).process(bundle(bob, corruptSigned, !corruptSigned))
            }
        }
    }

    @Test fun changedPeerIdentityCannotReplacePersistedTrust() {
        val alice = state(); val bob = state(); val aliceAddress = address(); val bobAddress = address()
        SessionBuilder(DeviceProtocolStore(alice), bobAddress, aliceAddress).process(bundle(bob))
        val restoredAlice = restored(alice)
        val store = DeviceProtocolStore(restoredAlice)
        val replacement = state()
        assertFalse(store.isTrustedIdentity(bobAddress, replacement.identity.pair.publicKey, IdentityKeyStore.Direction.RECEIVING))
        assertThrows(UntrustedIdentityException::class.java) {
            SessionBuilder(store, bobAddress, aliceAddress).process(bundle(replacement))
        }
        assertArrayEquals(bob.identity.pair.publicKey.serialize(), store.getIdentity(bobAddress)!!.serialize())
    }

    @Test fun loadedSessionIsACopyUntilExplicitlyStored() {
        val alice = state(); val bob = state(); val aliceAddress = address(); val bobAddress = address()
        val store = DeviceProtocolStore(alice)
        SessionBuilder(store, bobAddress, aliceAddress).process(bundle(bob))
        store.loadSession(bobAddress).archiveCurrentState()
        assertTrue(store.loadSession(bobAddress).hasSenderChain())
    }

    @Test fun consumedPrekeysAndKemReplayRecordsStayConsumedAfterRestore() {
        val state = state(); val store = DeviceProtocolStore(state)
        store.removePreKey(1)
        val baseKey = ECKeyPair.generate().publicKey
        store.markKyberPreKeyUsed(1, 1, baseKey)
        val restored = restored(state)
        restored.initializePreKeys(System.currentTimeMillis() + 1000)
        val restoredStore = DeviceProtocolStore(restored)
        assertFalse(restoredStore.containsPreKey(1))
        assertEquals(99, restored.preKeys.size)
        assertThrows(ReusedBaseKeyException::class.java) { restoredStore.markKyberPreKeyUsed(1, 1, baseKey) }
        assertEquals(state.bundleExpiresAt(), restored.bundleExpiresAt())
    }

    @Test fun corruptTruncatedTrailingAndOversizedStatesFailClosed() {
        val bytes = state().encode()
        try {
            assertThrows(IllegalArgumentException::class.java) { DeviceKeyState.decode(bytes.copyOf().apply { this[3] = 5 }) }
            assertThrows(Exception::class.java) { DeviceKeyState.decode(bytes.copyOf(bytes.size - 1)) }
            assertThrows(IllegalArgumentException::class.java) { DeviceKeyState.decode(bytes + byteArrayOf(1)) }
            assertThrows(IllegalArgumentException::class.java) { DeviceKeyState.decode(ByteArray(DeviceKeyState.MAX_BYTES + 1)) }
        } finally { bytes.fill(0) }
    }
}
