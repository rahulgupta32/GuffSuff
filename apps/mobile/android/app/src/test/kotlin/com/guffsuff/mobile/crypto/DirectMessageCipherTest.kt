// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.util.UUID
import org.junit.Assert.*
import org.junit.Test
import org.signal.libsignal.protocol.state.*

class DirectMessageCipherTest {
    private fun id() = UUID.randomUUID().toString()
    private fun state() = DeviceKeyState(IdentityMaterial.create()).apply { initializePreKeys(System.currentTimeMillis()) }
    private fun restore(state: DeviceKeyState) = DeviceKeyState.decode(state.encode())
    private fun bundle(state: DeviceKeyState): PreKeyBundle {
        val signed = SignedPreKeyRecord(state.signedPreKey!!); val kem = KyberPreKeyRecord(state.kemPreKey!!)
        val prekey = PreKeyRecord(state.preKeys.getValue(1))
        return PreKeyBundle(state.identity.registrationId, 1, prekey.id, prekey.keyPair.publicKey,
            signed.id, signed.keyPair.publicKey, signed.signature, state.identity.pair.publicKey,
            kem.id, kem.keyPair.publicKey, kem.signature)
    }
    private val now = System.currentTimeMillis()
    private val aliceUser = id(); private val aliceDevice = id(); private val bobUser = id()
    private fun route(device: String) = DirectMessageRoute(id(), aliceUser, aliceDevice, bobUser, device, now, now + 60000)

    @Test fun independentDeviceCiphertextsAndRetriesSurviveRestoration() {
        val alice = state(); val bobOne = state(); val bobTwo = state()
        val first = route(id()); val second = first.copy(recipientDeviceId = id()); val messageId = id()
        val routes = listOf(first, second)
        val cipher = DirectMessageCipher(alice, aliceUser, aliceDevice)
        val batch = cipher.send(messageId, routes, "गफसफ दुई उपकरण", mapOf(first.recipientDeviceId to bundle(bobOne), second.recipientDeviceId to bundle(bobTwo)), now)
        assertFalse(batch.getValue(first.recipientDeviceId).contentEquals(batch.getValue(second.recipientDeviceId)))
        val copy = restore(alice); val before = copy.sessions.mapValues { it.value.copyOf() }
        val retry = DirectMessageCipher(copy, aliceUser, aliceDevice).send(messageId, routes.reversed(), "गफसफ दुई उपकरण", emptyMap(), now)
        for ((device, bytes) in batch) assertArrayEquals(bytes, retry.getValue(device))
        for ((address, bytes) in before) assertArrayEquals(bytes, copy.sessions.getValue(address))
        for ((receiver, target) in listOf(bobOne to first, bobTwo to second)) {
            val received = DirectMessageCipher(receiver, bobUser, target.recipientDeviceId).receive(id(), target, batch.getValue(target.recipientDeviceId), now)
            assertEquals(messageId, received.messageId); assertEquals("गफसफ दुई उपकरण", received.text)
            assertEquals(target, received.route)
        }
    }

    @Test fun receivedDuplicateReturnsSameMessageWithoutDecryptingTwice() {
        val alice = state(); val bob = state(); val route = route(id()); val envelope = id(); val messageId = id()
        val wire = DirectMessageCipher(alice, aliceUser, aliceDevice).send(messageId, listOf(route), "hello", mapOf(route.recipientDeviceId to bundle(bob)), now).getValue(route.recipientDeviceId)
        val first = DirectMessageCipher(bob, bobUser, route.recipientDeviceId).receive(envelope, route, wire, now)
        val restored = restore(bob); val before = restored.encode()
        assertEquals(first, DirectMessageCipher(restored, bobUser, route.recipientDeviceId).receive(envelope, route, wire, now))
        assertArrayEquals(before, restored.encode())
    }

    @Test fun changedConversationSenderRecipientTimestampsAndProtocolCannotBeAccepted() {
        val alice = state(); val bob = state(); val route = route(id())
        val wire = DirectMessageCipher(alice, aliceUser, aliceDevice).send(id(), listOf(route), "bound routing", mapOf(route.recipientDeviceId to bundle(bob)), now).getValue(route.recipientDeviceId)
        val altered = listOf(route.copy(conversationId = id()), route.copy(senderUserId = id()), route.copy(senderDeviceId = id()),
            route.copy(recipientUserId = id()), route.copy(recipientDeviceId = id()), route.copy(createdAtMillis = now - 1), route.copy(expiresAtMillis = now + 60001))
        for (expected in altered) {
            val staged = restore(bob)
            assertThrows(Exception::class.java) { DirectMessageCipher(staged, bobUser, route.recipientDeviceId).receive(id(), expected, wire, now) }
            assertTrue(staged.inbox.isEmpty())
        }
        assertThrows(IllegalArgumentException::class.java) { route.copy(protocolVersion = 1) }
    }

    @Test fun tamperedCiphertextTypeFramingAndPayloadFailClosed() {
        val alice = state(); val bob = state(); val route = route(id())
        val wire = DirectMessageCipher(alice, aliceUser, aliceDevice).send(id(), listOf(route), "integrity", mapOf(route.recipientDeviceId to bundle(bob)), now).getValue(route.recipientDeviceId)
        val variants = listOf(wire.copyOf().apply { this[0] = 0 }, wire.copyOf().apply { this[7] = 8 },
            wire.copyOf().apply { this[lastIndex] = (this[lastIndex].toInt() xor 1).toByte() }, wire.dropLast(1).toByteArray(), wire + byteArrayOf(1))
        for (changed in variants) assertThrows(Exception::class.java) {
            DirectMessageCipher(restore(bob), bobUser, route.recipientDeviceId).receive(id(), route, changed, now)
        }
    }

    @Test fun changedIntentInventoryMissingClaimsScopeAndExpiryFail() {
        val alice = state(); val bob = state(); val route = route(id()); val message = id()
        val cipher = DirectMessageCipher(alice, aliceUser, aliceDevice)
        cipher.send(message, listOf(route), "original", mapOf(route.recipientDeviceId to bundle(bob)), now)
        assertThrows(IllegalStateException::class.java) { cipher.send(message, listOf(route), "changed", emptyMap(), now) }
        assertThrows(IllegalStateException::class.java) { cipher.send(message, listOf(route, route.copy(recipientDeviceId = id())), "original", emptyMap(), now) }
        assertThrows(IllegalStateException::class.java) { cipher.send(id(), listOf(route.copy(recipientDeviceId = id())), "new target", emptyMap(), now) }
        assertThrows(IllegalArgumentException::class.java) { cipher.send(id(), listOf(route, route), "duplicate targets", emptyMap(), now) }
        assertThrows(IllegalArgumentException::class.java) { cipher.send(id(), listOf(route.copy(senderUserId = id())), "wrong scope", emptyMap(), now) }
        assertThrows(IllegalArgumentException::class.java) { cipher.send(message, listOf(route), "original", emptyMap(), route.expiresAtMillis) }
        assertThrows(Exception::class.java) { cipher.send(id(), listOf(route), "\uD800", emptyMap(), now) }
    }

    @Test fun signedOnlyFallbackAndOversizedFanoutAreRejected() {
        val alice = state(); val bob = state(); val route = route(id())
        val valid = bundle(bob)
        val withoutOneTimeKey = PreKeyBundle(valid.registrationId, 1, -1, null, valid.signedPreKeyId,
            valid.signedPreKey, valid.signedPreKeySignature, valid.identityKey, valid.kyberPreKeyId, valid.kyberPreKey, valid.kyberPreKeySignature)
        assertThrows(IllegalArgumentException::class.java) {
            DirectMessageCipher(alice, aliceUser, aliceDevice).send(id(), listOf(route), "no fallback", mapOf(route.recipientDeviceId to withoutOneTimeKey), now)
        }
        assertTrue(alice.sessions.isEmpty() && alice.outbox.isEmpty())
        val routes = (1..9).map { route.copy(recipientDeviceId = id()) }
        val bundles = routes.associate { it.recipientDeviceId to bundle(state()) }
        assertThrows(IllegalArgumentException::class.java) {
            DirectMessageCipher(state(), aliceUser, aliceDevice).send(id(), routes, "a".repeat(8192), bundles, now)
        }
    }

    @Test fun replyUsesRestoredSessionAndChangedPeerIdentityCannotReplacePin() {
        val alice = state(); val bob = state(); val route = route(id())
        val outgoing = DirectMessageCipher(alice, aliceUser, aliceDevice).send(id(), listOf(route), "first", mapOf(route.recipientDeviceId to bundle(bob)), now).getValue(route.recipientDeviceId)
        DirectMessageCipher(bob, bobUser, route.recipientDeviceId).receive(id(), route, outgoing, now)
        val replyRoute = DirectMessageRoute(route.conversationId, bobUser, route.recipientDeviceId, aliceUser, aliceDevice, now, now + 60000)
        val reply = DirectMessageCipher(restore(bob), bobUser, route.recipientDeviceId).send(id(), listOf(replyRoute), "reply", emptyMap(), now).getValue(aliceDevice)
        assertEquals("reply", DirectMessageCipher(restore(alice), aliceUser, aliceDevice).receive(id(), replyRoute, reply, now).text)
        assertThrows(IllegalStateException::class.java) {
            DirectMessageCipher(restore(alice), aliceUser, aliceDevice).send(id(), listOf(route), "changed peer", mapOf(route.recipientDeviceId to bundle(state())), now)
        }
    }
}
