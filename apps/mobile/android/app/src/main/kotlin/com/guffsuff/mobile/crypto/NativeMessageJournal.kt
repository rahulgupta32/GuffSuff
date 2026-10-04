// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.io.DataInputStream
import java.io.DataOutputStream
import java.security.MessageDigest

/** Internal transaction primitive. Not a transport codec or an enabled Flutter provider. */
internal class NativeMessageJournal(private val state: DeviceKeyState) {
    /**
     * canonicalIntent must bind the complete routing, device inventory, protocol, timestamps and
     * plaintext. The future authenticated provider owns that encoding. A retry never runs encrypt.
     * The callback must stage ALL recipient sessions in this same state and return the exact batch.
     */
    fun outgoing(id: String, canonicalIntent: ByteArray, encrypt: () -> Pair<ByteArray, ByteArray>): JournalRecord {
        validateId(id)
        val commitment = commitment("outgoing", canonicalIntent)
        state.outbox[id]?.let { return matching(it, commitment) }
        check(state.outbox.size < MAX_OUTBOX) { "Outbox capacity exceeded" }
        val (ciphertextBatch, localHistory) = encrypt()
        val record = JournalRecord(commitment, ciphertextBatch, localHistory, false)
        state.outbox[id] = record
        return record.copy()
    }

    /**
     * canonicalEnvelope must include ALL authenticated routing and ciphertext. The callback must
     * verify encrypted routing before returning plaintext. Retry returns history without decrypting.
     * DeviceIdentityStore.withState must commit this record and the ratchet before delivery ACK.
     */
    fun incoming(id: String, canonicalEnvelope: ByteArray, decrypt: () -> ByteArray): ByteArray {
        validateId(id)
        val commitment = commitment("incoming", canonicalEnvelope)
        state.inbox[id]?.let { return matching(it, commitment).history() }
        check(state.inbox.size < MAX_INBOX) { "History capacity exceeded" }
        val record = JournalRecord(commitment, byteArrayOf(), decrypt(), true, incoming = true)
        state.inbox[id] = record
        return record.history()
    }

    /** Retain the exact batch and commitment after acceptance: delayed retries must not re-encrypt. */
    fun markAccepted(id: String, canonicalIntent: ByteArray) {
        validateId(id)
        val record = state.outbox[id] ?: error("Unknown outbox entry")
        matching(record, commitment("outgoing", canonicalIntent))
        state.outbox[id] = record.accepted()
    }

    fun pending(): Map<String, JournalRecord> = state.outbox.filterValues { !it.isAccepted }.mapValues { it.value.copy() }

    private fun matching(record: JournalRecord, commitment: ByteArray): JournalRecord {
        check(MessageDigest.isEqual(record.commitment(), commitment)) { "Message identifier reused with different content" }
        return record.copy()
    }

    companion object {
        const val MAX_OUTBOX = 64
        const val MAX_INBOX = 128
        const val MAX_BATCH = 65536
        const val MAX_HISTORY = 16384
        const val MAX_INTENT = 131072
        private val uuid = Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
        private fun validateId(id: String) { require(uuid.matches(id)) { "Invalid message identifier" } }
        private fun commitment(direction: String, bytes: ByteArray): ByteArray {
            require(bytes.size in 1..MAX_INTENT) { "Invalid canonical message length" }
            val hash = MessageDigest.getInstance("SHA-256")
            hash.update("guffsuff/native-journal/v1/$direction\u0000".toByteArray(Charsets.UTF_8))
            return hash.digest(bytes)
        }

        fun write(stream: DataOutputStream, records: Map<String, JournalRecord>, incoming: Boolean) {
            require(records.size <= if (incoming) MAX_INBOX else MAX_OUTBOX)
            stream.writeInt(records.size)
            for ((id, record) in records) {
                validateId(id); stream.writeUTF(id)
                require(record.isIncoming == incoming)
                record.write(stream)
            }
        }

        fun read(stream: DataInputStream, incoming: Boolean): Map<String, JournalRecord> {
            val count = stream.readInt()
            require(count in 0..(if (incoming) MAX_INBOX else MAX_OUTBOX))
            val result = sortedMapOf<String, JournalRecord>()
            repeat(count) {
                val id = stream.readUTF(); validateId(id)
                require(!result.containsKey(id)) { "Duplicate journal identifier" }
                result[id] = JournalRecord.read(stream, incoming)
            }
            return result
        }
    }
}

/** Defensive copies prevent a caller from changing a persisted retry or local history in memory. */
internal class JournalRecord(
    commitment: ByteArray,
    ciphertext: ByteArray,
    history: ByteArray,
    val isAccepted: Boolean,
    val isIncoming: Boolean = false
) {
    private val digest = commitment.copyOf()
    private val batch = ciphertext.copyOf()
    private val plaintext = history.copyOf()
    init {
        require(digest.size == 32)
        require(batch.size in (if (isIncoming) 0 else 1)..NativeMessageJournal.MAX_BATCH)
        require(!isIncoming || (batch.isEmpty() && isAccepted))
        require(plaintext.size in 1..NativeMessageJournal.MAX_HISTORY)
    }
    fun commitment() = digest.copyOf()
    fun ciphertext() = batch.copyOf()
    fun history() = plaintext.copyOf()
    fun copy() = JournalRecord(digest, batch, plaintext, isAccepted, isIncoming)
    fun accepted() = JournalRecord(digest, batch, plaintext, true, isIncoming)
    fun write(stream: DataOutputStream) {
        stream.write(digest); stream.writeByte(if (isAccepted) 1 else 0)
        stream.writeInt(batch.size); stream.write(batch)
        stream.writeInt(plaintext.size); stream.write(plaintext)
    }
    companion object {
        fun read(stream: DataInputStream, incoming: Boolean): JournalRecord {
            val digest = ByteArray(32).also { stream.readFully(it) }
            val status = stream.readUnsignedByte(); require(status in 0..1)
            fun blob(min: Int, max: Int): ByteArray {
                val length = stream.readInt(); require(length in min..max && length <= stream.available())
                return ByteArray(length).also { stream.readFully(it) }
            }
            return JournalRecord(digest, blob(if (incoming) 0 else 1, NativeMessageJournal.MAX_BATCH),
                blob(1, NativeMessageJournal.MAX_HISTORY), status == 1, incoming)
        }
    }
}
