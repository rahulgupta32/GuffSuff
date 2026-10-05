// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.util.Base64
import java.util.UUID
import org.junit.Assert.*
import org.junit.Test
import org.signal.libsignal.protocol.state.*

class DirectMessageRecoveryTest {
    private fun id() = UUID.randomUUID().toString()
    private val now = System.currentTimeMillis()
    private val alice = id(); private val aliceDevice = id(); private val bob = id(); private val bobDevice = id()
    private val conversation = id()
    private fun route() = DirectMessageRoute(conversation, alice, aliceDevice, bob, bobDevice, now, now + 60000)
    private fun freshState() = DeviceKeyState(IdentityMaterial.create()).apply { initializePreKeys(now) }
    private fun restore(state: DeviceKeyState) = DeviceKeyState.decode(state.encode())
    private fun bundle(state: DeviceKeyState): PreKeyBundle {
        val signed = SignedPreKeyRecord(state.signedPreKey!!); val kem = KyberPreKeyRecord(state.kemPreKey!!)
        val prekey = PreKeyRecord(state.preKeys.getValue(1))
        return PreKeyBundle(state.identity.registrationId, 1, prekey.id, prekey.keyPair.publicKey,
            signed.id, signed.keyPair.publicKey, signed.signature, state.identity.pair.publicKey,
            kem.id, kem.keyPair.publicKey, kem.signature)
    }
    private fun fingerprint(row: Map<String, Any>) = Base64.getDecoder().decode(row.getValue("batchFingerprintBase64") as String)

    @Test fun restoredBatchAcceptanceAndHistoryPreserveExactCiphertextAndRatchets() {
        val state = freshState(); val peer = freshState(); val second = freshState(); val message = id(); val envelope = id()
        val firstRoute = route(); val routes = listOf(firstRoute, firstRoute.copy(recipientDeviceId = id()))
        val original = DirectMessageCipher(state, alice, aliceDevice).send(message, routes, "नमस्ते recovery",
            mapOf(bobDevice to bundle(peer), routes[1].recipientDeviceId to bundle(second)), now)
        val restored = restore(state); val before = restored.encode()
        val recovery = DirectMessageRecovery(restored, alice, aliceDevice)
        val pending = recovery.pending(conversation).single()
        assertEquals(setOf("messageId", "route", "batchFingerprintBase64", "deviceEnvelopes"), pending.keys)
        for (value in pending.getValue("deviceEnvelopes") as List<*>) {
            val row = value as Map<*, *>
            assertArrayEquals(original.getValue(row["recipientDeviceId"] as String),
                Base64.getDecoder().decode(row["opaquePayloadBase64"] as String))
        }
        assertTrue(recovery.pending(id()).isEmpty()); assertArrayEquals(before, restored.encode())
        val wrong = fingerprint(pending).apply { this[0] = (this[0].toInt() xor 1).toByte() }
        assertThrows(IllegalArgumentException::class.java) { recovery.accepted(message, envelope, wrong) }
        assertArrayEquals(before, restored.encode())
        recovery.accepted(message, envelope, fingerprint(pending))
        val committed = restore(restored); val acceptedBytes = committed.encode()
        val accepted = DirectMessageRecovery(committed, alice, aliceDevice)
        assertTrue(accepted.pending(conversation).isEmpty())
        assertEquals(envelope, committed.acceptedEnvelopes[message])
        accepted.accepted(message, envelope, fingerprint(pending)); assertArrayEquals(acceptedBytes, committed.encode())
        assertThrows(IllegalArgumentException::class.java) { accepted.accepted(message, id(), fingerprint(pending)) }
        assertArrayEquals(acceptedBytes, committed.encode())
        val retried = DirectMessageCipher(committed, alice, aliceDevice).send(message, routes, "नमस्ते recovery", emptyMap(), now)
        original.forEach { (device, bytes) -> assertArrayEquals(bytes, retried.getValue(device)) }
        assertArrayEquals(acceptedBytes, committed.encode())
        val history = accepted.history(conversation).single()
        assertEquals("नमस्ते recovery", history["text"]); assertEquals(envelope, history["serverEnvelopeId"])
        assertEquals(true, history["isAccepted"]); assertEquals("outgoing", history["direction"])
        assertTrue(accepted.history(id()).isEmpty())
    }

    @Test fun incomingHistoryUsesEnvelopeIdAndRemainsReadableWithoutDecryptingAgain() {
        val sender = freshState(); val receiver = freshState(); val message = id(); val envelope = id(); val route = route()
        val wire = DirectMessageCipher(sender, alice, aliceDevice).send(message, listOf(route), "verified history",
            mapOf(bobDevice to bundle(receiver)), now).getValue(bobDevice)
        DirectMessageCipher(receiver, bob, bobDevice).receive(envelope, route, wire, now)
        val restored = restore(receiver); val before = restored.encode()
        val row = DirectMessageRecovery(restored, bob, bobDevice).history(conversation).single()
        assertEquals(message, row["messageId"]); assertEquals(envelope, row["recordId"])
        assertEquals(envelope, row["serverEnvelopeId"]); assertEquals("incoming", row["direction"])
        assertEquals("verified history", row["text"]); assertArrayEquals(before, restored.encode())
        assertThrows(IllegalArgumentException::class.java) { DirectMessageRecovery(restored, alice, aliceDevice).history(conversation) }
        assertArrayEquals(before, restored.encode())
    }

    @Test fun formatThreeMigratesAcceptedHistoryWithoutInventingServerMappings() {
        val sender = freshState(); val message = id(); val route = route()
        DirectMessageCipher(sender, alice, aliceDevice).send(message, listOf(route), "legacy history",
            mapOf(bobDevice to bundle(freshState())), now)
        val pending = DirectMessageRecovery(sender, alice, aliceDevice).pending(conversation).single()
        val envelope = id()
        DirectMessageRecovery(sender, alice, aliceDevice).accepted(message, envelope, fingerprint(pending))
        // Existing format-3 accepted tombstones had no envelope-ID table.
        sender.acceptedEnvelopes.clear()
        val legacy = sender.encode().dropLast(8).toByteArray().apply { this[3] = 3 }
        val restored = DeviceKeyState.decode(legacy)
        assertTrue(restored.outbox.getValue(message).isAccepted && restored.acceptedEnvelopes.isEmpty())
        val recovery = DirectMessageRecovery(restored, alice, aliceDevice)
        assertNull(recovery.history(conversation).single()["serverEnvelopeId"])
        recovery.accepted(message, envelope, fingerprint(pending))
        assertEquals(envelope, restore(restored).acceptedEnvelopes[message])
        assertArrayEquals(sender.identity.pair.publicKey.serialize(), restored.identity.pair.publicKey.serialize())
    }

    @Test fun inconsistentJournalCommitmentAndReceiptTablesFailClosed() {
        val state = freshState(); val message = id()
        DirectMessageCipher(state, alice, aliceDevice).send(message, listOf(route()), "bound history",
            mapOf(bobDevice to bundle(freshState())), now)
        val original = state.outbox.getValue(message)
        state.outbox[message] = JournalRecord(ByteArray(32), original.ciphertext(), original.history(), false)
        assertThrows(IllegalStateException::class.java) { DirectMessageRecovery(state, alice, aliceDevice).pending(conversation) }
        state.outbox[message] = original
        state.acceptedEnvelopes[message] = id()
        assertThrows(IllegalArgumentException::class.java) { state.encode() }
        state.acceptedEnvelopes.clear()
        assertThrows(IllegalArgumentException::class.java) { DirectMessageRecovery(state, alice, aliceDevice).pending("invalid") }
        assertThrows(IllegalArgumentException::class.java) { DirectMessageRecovery(state, alice, aliceDevice).accepted(message, "invalid", ByteArray(32)) }
        val recovery = DirectMessageRecovery(state, alice, aliceDevice)
        recovery.accepted(message, id(), fingerprint(recovery.pending(conversation).single()))
        val encoded = state.encode()
        assertThrows(IllegalArgumentException::class.java) {
            DeviceKeyState.decode(encoded.copyOf().apply { this[size - 40] = 'g'.code.toByte() })
        }
        val unknown = id().toByteArray(Charsets.UTF_8)
        assertThrows(IllegalArgumentException::class.java) {
            DeviceKeyState.decode(encoded.copyOf().apply { System.arraycopy(unknown, 0, this, size - 78, 36) })
        }
    }

    @Test fun differentMessagesCannotShareAcceptedServerEnvelopeId() {
        val sender = freshState(); val first = id(); val second = id(); val envelope = id(); val route = route()
        val cipher = DirectMessageCipher(sender, alice, aliceDevice)
        cipher.send(first, listOf(route), "first", mapOf(bobDevice to bundle(freshState())), now)
        cipher.send(second, listOf(route), "second", emptyMap(), now)
        val recovery = DirectMessageRecovery(sender, alice, aliceDevice)
        val rows = recovery.pending(conversation).associateBy { it.getValue("messageId") as String }
        recovery.accepted(first, envelope, fingerprint(rows.getValue(first)))
        val before = sender.encode()
        assertThrows(IllegalArgumentException::class.java) { recovery.accepted(second, envelope, fingerprint(rows.getValue(second))) }
        assertArrayEquals(before, sender.encode())
        assertEquals(setOf(second), recovery.pending(conversation).map { it.getValue("messageId") }.toSet())
    }
}
