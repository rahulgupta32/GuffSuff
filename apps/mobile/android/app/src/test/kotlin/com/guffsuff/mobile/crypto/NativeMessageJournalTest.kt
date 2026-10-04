// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.util.UUID
import org.junit.Assert.*
import org.junit.Test

class NativeMessageJournalTest {
    private fun id() = UUID.randomUUID().toString()
    private fun state() = DeviceKeyState(IdentityMaterial.create())
    private fun restore(state: DeviceKeyState) = DeviceKeyState.decode(state.encode())

    @Test fun outgoingRetryAndAcceptedTombstoneNeverInvokeEncryptionAgain() {
        var state = state(); val id = id(); val intent = "canonical intent".toByteArray()
        val first = NativeMessageJournal(state).outgoing(id, intent) { byteArrayOf(3, 4) to "गफसफ".toByteArray() }
        state = restore(state)
        val journal = NativeMessageJournal(state)
        assertArrayEquals(first.ciphertext(), journal.outgoing(id, intent) { error("Retry must not encrypt") }.ciphertext())
        assertEquals(setOf(id), journal.pending().keys)
        journal.markAccepted(id, intent)
        assertTrue(NativeMessageJournal(restore(state)).pending().isEmpty())
        assertArrayEquals(first.ciphertext(), NativeMessageJournal(restore(state)).outgoing(id, intent) {
            error("Accepted retry must not encrypt")
        }.ciphertext())
        assertThrows(IllegalStateException::class.java) {
            journal.outgoing(id, "changed intent".toByteArray()) { error("Must reject before encryption") }
        }
        assertThrows(IllegalStateException::class.java) { journal.markAccepted(id, "changed intent".toByteArray()) }
    }

    @Test fun incomingRetryReturnsCommittedHistoryWithoutDecryptingAgain() {
        val state = state(); val id = id(); val envelope = byteArrayOf(1, 2)
        val expected = "received message".toByteArray()
        assertArrayEquals(expected, NativeMessageJournal(state).incoming(id, envelope) { expected })
        val journal = NativeMessageJournal(restore(state))
        assertArrayEquals(expected, journal.incoming(id, envelope) { error("Duplicate must not decrypt") })
        assertThrows(IllegalStateException::class.java) { journal.incoming(id, byteArrayOf(2, 1)) { error("Changed envelope") } }
    }

    @Test fun inputsAndReturnedArraysCannotMutateRetryOrHistory() {
        val state = state(); val id = id(); val intent = byteArrayOf(1)
        val ciphertext = byteArrayOf(2); val history = byteArrayOf(3)
        val record = NativeMessageJournal(state).outgoing(id, intent) { ciphertext to history }
        ciphertext.fill(9); history.fill(9); record.ciphertext().fill(9); record.history().fill(9); record.commitment().fill(9)
        val pending = NativeMessageJournal(restore(state)).pending().getValue(id)
        assertArrayEquals(byteArrayOf(2), pending.ciphertext())
        assertArrayEquals(byteArrayOf(3), pending.history())
    }

    @Test fun journalCapacityRejectsBeforeCryptoCallbackAndDoesNotEvictRetries() {
        val state = state(); val journal = NativeMessageJournal(state)
        repeat(NativeMessageJournal.MAX_OUTBOX) { journal.outgoing(id(), byteArrayOf(1)) { byteArrayOf(2) to byteArrayOf(3) } }
        assertThrows(IllegalStateException::class.java) { journal.outgoing(id(), byteArrayOf(1)) { error("Capacity must check first") } }
        repeat(NativeMessageJournal.MAX_INBOX) { journal.incoming(id(), byteArrayOf(1)) { byteArrayOf(3) } }
        assertThrows(IllegalStateException::class.java) { journal.incoming(id(), byteArrayOf(1)) { error("Capacity must check first") } }
        assertEquals(NativeMessageJournal.MAX_OUTBOX, restore(state).outbox.size)
        assertEquals(NativeMessageJournal.MAX_INBOX, restore(state).inbox.size)
    }

    @Test fun legacyVersionTwoMigratesWithoutReplacingKeys() {
        val state = state()
        // An empty format-3 journal appends two zero counts to the otherwise unchanged format-2 record.
        val bytes = state.encode().dropLast(8).toByteArray().apply { this[3] = 2 }
        val restored = DeviceKeyState.decode(bytes)
        assertArrayEquals(state.identity.pair.publicKey.serialize(), restored.identity.pair.publicKey.serialize())
        assertEquals(state.identity.registrationId, restored.identity.registrationId)
        assertTrue(restored.outbox.isEmpty() && restored.inbox.isEmpty())
        assertEquals(3, restored.encode()[3].toInt())
    }

    @Test fun malformedAndOversizedJournalRecordsFailClosed() {
        val state = state(); val journal = NativeMessageJournal(state)
        assertThrows(IllegalArgumentException::class.java) { journal.outgoing("../invalid", byteArrayOf(1)) { error("Invalid ID") } }
        assertThrows(IllegalArgumentException::class.java) { journal.incoming(id(), byteArrayOf()) { error("Empty input") } }
        assertThrows(IllegalArgumentException::class.java) {
            journal.outgoing(id(), byteArrayOf(1)) { ByteArray(NativeMessageJournal.MAX_BATCH + 1) to byteArrayOf(1) }
        }
        assertTrue(state.outbox.isEmpty())
        repeat(20) { journal.outgoing(id(), byteArrayOf(1)) { ByteArray(NativeMessageJournal.MAX_BATCH) to byteArrayOf(1) } }
        assertThrows(IllegalArgumentException::class.java) { state.encode() }
    }
}
