// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.util.UUID
import org.junit.Assert.*
import org.junit.Test

class PreparedDirectMessageTest {
    private fun id() = UUID.randomUUID().toString()
    private fun route() = DirectMessageRoute(id(), id(), id(), id(), id(), 1000L, 100000L)

    @Test fun restoredIntentRetainsClaimIdsWithoutCreatingSessions() {
        val state = DeviceKeyState(IdentityMaterial.create())
        val route = route(); val message = id()
        val prepared = PreparedDirectMessage.prepare(state, route.senderUserId, route.senderDeviceId,
            message, listOf(route), "गफसफ", 2000L)
        val restored = DeviceKeyState.decode(state.encode())
        val again = PreparedDirectMessage.prepare(restored, route.senderUserId, route.senderDeviceId,
            message, listOf(route), "गफसफ", 2000L)
        assertEquals(prepared.claimIds, again.claimIds)
        assertEquals(listOf(route.recipientDeviceId), again.requiredClaimDeviceIds(restored))
        assertTrue(restored.sessions.isEmpty())
        assertTrue(restored.outbox.isEmpty())
        assertThrows(IllegalArgumentException::class.java) {
            PreparedDirectMessage.prepare(restored, route.senderUserId, route.senderDeviceId,
                message, listOf(route), "changed", 2000L)
        }
        assertThrows(IllegalArgumentException::class.java) {
            PreparedDirectMessage.prepare(restored, route.senderUserId, route.senderDeviceId,
                message, listOf(route.copy(expiresAtMillis = 110000L)), "गफसफ", 2000L)
        }
    }

    @Test fun invalidScopeExpiryAndInventoryCannotReserveCapacity() {
        val state = DeviceKeyState(IdentityMaterial.create()); val route = route()
        for (routes in listOf(emptyList(), listOf(route, route))) {
            assertThrows(IllegalArgumentException::class.java) {
                PreparedDirectMessage.prepare(state, route.senderUserId, route.senderDeviceId,
                    id(), routes, "text", 2000L)
            }
        }
        assertThrows(IllegalArgumentException::class.java) {
            PreparedDirectMessage.prepare(state, id(), route.senderDeviceId, id(), listOf(route), "text", 2000L)
        }
        assertThrows(IllegalArgumentException::class.java) {
            PreparedDirectMessage.prepare(state, route.senderUserId, route.senderDeviceId,
                id(), listOf(route), "text", route.expiresAtMillis)
        }
        assertTrue(state.prepared.isEmpty())
    }

    @Test fun reservationsAreBoundedAndCorruptDraftsFailClosed() {
        val state = DeviceKeyState(IdentityMaterial.create()); val route = route()
        repeat(NativeMessageJournal.MAX_OUTBOX) {
            PreparedDirectMessage.prepare(state, route.senderUserId, route.senderDeviceId,
                id(), listOf(route), "text", 2000L)
        }
        assertThrows(IllegalArgumentException::class.java) {
            PreparedDirectMessage.prepare(state, route.senderUserId, route.senderDeviceId,
                id(), listOf(route), "text", 2000L)
        }
        assertEquals(64, DeviceKeyState.decode(state.encode()).prepared.size)
        val bytes = state.encode()
        assertThrows(Exception::class.java) { DeviceKeyState.decode(bytes.copyOf(bytes.size - 1)) }
        assertThrows(IllegalArgumentException::class.java) {
            DeviceKeyState.decode(bytes.copyOf().apply { this[lastIndex] = 'g'.code.toByte() })
        }
    }

    @Test fun formatFourMigrationPreservesIdentityAndDoesNotInventDrafts() {
        val state = DeviceKeyState(IdentityMaterial.create())
        val legacy = state.encode().dropLast(4).toByteArray().apply { this[3] = 4 }
        val restored = DeviceKeyState.decode(legacy)
        assertArrayEquals(state.identity.pair.publicKey.serialize(), restored.identity.pair.publicKey.serialize())
        assertTrue(restored.prepared.isEmpty())
        assertEquals(5, restored.encode()[3].toInt())
    }
}
