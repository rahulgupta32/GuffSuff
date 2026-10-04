// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.util.UUID
import org.signal.libsignal.protocol.SessionBuilder
import org.signal.libsignal.protocol.SessionCipher
import org.signal.libsignal.protocol.message.CiphertextMessage
import org.signal.libsignal.protocol.message.PreKeySignalMessage
import org.signal.libsignal.protocol.message.SignalMessage
import org.signal.libsignal.protocol.state.PreKeyBundle
import org.signal.libsignal.protocol.state.IdentityKeyStore

/** Epoch milliseconds avoid JSON/PostgreSQL differences in ISO fractional-second formatting. */
internal data class DirectMessageRoute(
    val conversationId: String,
    val senderUserId: String,
    val senderDeviceId: String,
    val recipientUserId: String,
    val recipientDeviceId: String,
    val createdAtMillis: Long,
    val expiresAtMillis: Long,
    val protocolVersion: Int = 2
) {
    init {
        listOf(conversationId, senderUserId, senderDeviceId, recipientUserId, recipientDeviceId).forEach { checkedUuid(it) }
        require(senderUserId != recipientUserId && senderDeviceId != recipientDeviceId)
        require(protocolVersion == 2 && createdAtMillis > 0 && expiresAtMillis > createdAtMillis)
    }
    fun write(stream: DataOutputStream) {
        stream.writeInt(protocolVersion)
        listOf(conversationId, senderUserId, senderDeviceId, recipientUserId, recipientDeviceId).forEach { stream.uuid(it) }
        stream.writeLong(createdAtMillis); stream.writeLong(expiresAtMillis)
    }
    companion object {
        fun read(stream: DataInputStream): DirectMessageRoute {
            val version = stream.readInt()
            val ids = (1..5).map { stream.uuid() }
            return DirectMessageRoute(ids[0], ids[1], ids[2], ids[3], ids[4], stream.readLong(), stream.readLong(), version)
        }
    }
}

internal data class ReceivedDirectMessage(val messageId: String, val route: DirectMessageRoute, val text: String)

/**
 * Only invoke on a staged state within DeviceIdentityStore.withState (see protected wrappers below).
 * The caller must obtain authorized device inventory/bundles and authenticated download metadata.
 * This class verifies cryptographic signatures/identity pins, not conversation membership on the API.
 */
internal class DirectMessageCipher(private val state: DeviceKeyState, private val accountId: String, private val deviceId: String) {
    init { checkedUuid(accountId); checkedUuid(deviceId) }

    fun send(messageId: String, routes: List<DirectMessageRoute>, text: String,
        claimedBundles: Map<String, PreKeyBundle>, nowMillis: Long): Map<String, ByteArray> {
        checkedUuid(messageId)
        require(routes.size in 1..16)
        val sorted = routes.sortedBy { it.recipientDeviceId }
        require(sorted.map { it.recipientDeviceId }.toSet().size == sorted.size)
        val first = sorted.first()
        require(first.senderUserId == accountId && first.senderDeviceId == deviceId)
        require(sorted.all { it == first.copy(recipientDeviceId = it.recipientDeviceId) }) { "Inconsistent batch routing" }
        require(nowMillis > 0 && first.expiresAtMillis > nowMillis) { "Message expired" }
        require(claimedBundles.keys.all { id -> sorted.any { it.recipientDeviceId == id } })
        val textBytes = encodeText(text)
        val intent = encode { stream ->
            stream.writeInt(INTENT_MAGIC); stream.uuid(messageId); stream.writeInt(sorted.size)
            for (route in sorted) route.write(stream)
            stream.blob(textBytes, MAX_TEXT)
        }
        try {
            val record = NativeMessageJournal(state).outgoing(messageId, intent) {
                val store = DeviceProtocolStore(state)
                val local = DeviceProtocolStore.deviceAddress(deviceId)
                val batch = encode { stream ->
                    stream.writeInt(BATCH_MAGIC); stream.writeInt(sorted.size)
                    for (route in sorted) {
                        val remote = DeviceProtocolStore.deviceAddress(route.recipientDeviceId)
                        val claimed = claimedBundles[route.recipientDeviceId]
                        if (claimed != null) {
                            require(claimed.deviceId == 1 && claimed.preKeyId >= 0 && claimed.preKey != null) {
                                "A claimed one-time prekey is required; signed-only fallback is disabled"
                            }
                            check(store.isTrustedIdentity(remote, claimed.identityKey, IdentityKeyStore.Direction.SENDING)) {
                                "Peer identity change requires verification"
                            }
                        }
                        if (!store.containsSession(remote)) {
                            val bundle = claimed ?: error("Claimed prekey required")
                            require(bundle.deviceId == 1)
                            SessionBuilder(store, remote, local).process(bundle)
                        }
                        val plaintext = payload(messageId, route, textBytes)
                        val wire = try {
                            val encrypted = SessionCipher(store, local, remote).encrypt(plaintext)
                            encode { out -> out.writeInt(WIRE_MAGIC); out.writeInt(encrypted.type); out.blob(encrypted.serialize(), MAX_WIRE) }
                        } finally { plaintext.fill(0) }
                        stream.uuid(route.recipientDeviceId); stream.blob(wire, MAX_WIRE)
                    }
                }
                require(batch.size <= NativeMessageJournal.MAX_BATCH) { "Ciphertext batch capacity exceeded" }
                batch to payload(messageId, first, textBytes)
            }
            return decodeBatch(record.ciphertext())
        } finally { textBytes.fill(0); intent.fill(0) }
    }

    fun receive(envelopeId: String, expected: DirectMessageRoute, wire: ByteArray, nowMillis: Long): ReceivedDirectMessage {
        require(wire.size in 13..MAX_WIRE)
        val snapshot = wire.copyOf()
        try { return receiveSnapshot(envelopeId, expected, snapshot, nowMillis) }
        finally { snapshot.fill(0) }
    }

    private fun receiveSnapshot(envelopeId: String, expected: DirectMessageRoute, wire: ByteArray, nowMillis: Long): ReceivedDirectMessage {
        checkedUuid(envelopeId)
        require(expected.recipientUserId == accountId && expected.recipientDeviceId == deviceId)
        require(nowMillis > 0 && expected.expiresAtMillis > nowMillis) { "Message expired" }
        require(wire.size in 13..MAX_WIRE)
        val canonicalEnvelope = encode { stream -> expected.write(stream); stream.blob(wire, MAX_WIRE) }
        val history = NativeMessageJournal(state).incoming(envelopeId, canonicalEnvelope) {
            DataInputStream(ByteArrayInputStream(wire)).use { stream ->
                require(stream.readInt() == WIRE_MAGIC) { "Unsupported ciphertext format" }
                val type = stream.readInt(); val ciphertext = stream.blob(MAX_WIRE)
                require(stream.available() == 0) { "Trailing ciphertext data" }
                val cipher = SessionCipher(DeviceProtocolStore(state), DeviceProtocolStore.deviceAddress(deviceId),
                    DeviceProtocolStore.deviceAddress(expected.senderDeviceId))
                val plaintext = when (type) {
                    CiphertextMessage.PREKEY_TYPE -> cipher.decrypt(PreKeySignalMessage(ciphertext))
                    CiphertextMessage.WHISPER_TYPE -> cipher.decrypt(SignalMessage(ciphertext))
                    else -> throw IllegalArgumentException("Unsupported ciphertext type")
                }
                try {
                    require(decodePayload(plaintext).route == expected) { "Encrypted routing mismatch" }
                    plaintext.copyOf()
                } finally { plaintext.fill(0) }
            }
        }
        try { return decodePayload(history).also { require(it.route == expected) } }
        finally { history.fill(0); canonicalEnvelope.fill(0) }
    }

    companion object {
        private const val INTENT_MAGIC = 0x47534931 // GSI1
        private const val BATCH_MAGIC = 0x47534231 // GSB1
        private const val PAYLOAD_MAGIC = 0x47535031 // GSP1
        private const val WIRE_MAGIC = 0x47535731 // GSW1
        private const val MAX_TEXT = 8192
        private const val MAX_WIRE = 65536
        private fun encode(block: (DataOutputStream) -> Unit): ByteArray {
            val output = ByteArrayOutputStream()
            DataOutputStream(output).use(block)
            return output.toByteArray()
        }
        private fun encodeText(text: String): ByteArray {
            require(text.isNotBlank() && text.length <= MAX_TEXT)
            val bytes = Charsets.UTF_8.newEncoder().onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT).encode(java.nio.CharBuffer.wrap(text))
            require(bytes.remaining() in 1..MAX_TEXT)
            return ByteArray(bytes.remaining()).also { bytes.get(it) }
        }
        private fun payload(messageId: String, route: DirectMessageRoute, text: ByteArray): ByteArray = encode {
            it.writeInt(PAYLOAD_MAGIC); it.uuid(messageId); route.write(it); it.blob(text, MAX_TEXT)
        }
        private fun decodePayload(bytes: ByteArray): ReceivedDirectMessage {
            require(bytes.size in 1..NativeMessageJournal.MAX_HISTORY)
            return DataInputStream(ByteArrayInputStream(bytes)).use { stream ->
                require(stream.readInt() == PAYLOAD_MAGIC)
                val id = stream.uuid(); val route = DirectMessageRoute.read(stream); val textBytes = stream.blob(MAX_TEXT)
                try {
                    require(stream.available() == 0)
                    val text = Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
                        .onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(textBytes)).toString()
                    require(text.isNotBlank())
                    ReceivedDirectMessage(id, route, text)
                } finally { textBytes.fill(0) }
            }
        }
        private fun decodeBatch(bytes: ByteArray): Map<String, ByteArray> = DataInputStream(ByteArrayInputStream(bytes)).use { stream ->
            require(bytes.size in 1..NativeMessageJournal.MAX_BATCH && stream.readInt() == BATCH_MAGIC)
            val count = stream.readInt(); require(count in 1..16)
            val result = sortedMapOf<String, ByteArray>()
            repeat(count) {
                val id = stream.uuid(); require(!result.containsKey(id))
                result[id] = stream.blob(MAX_WIRE)
            }
            require(stream.available() == 0)
            result
        }
    }
}

internal fun DeviceIdentityStore.sendDirectMessage(accountId: String, deviceId: String, messageId: String,
    routes: List<DirectMessageRoute>, text: String, bundles: Map<String, PreKeyBundle>, nowMillis: Long): Map<String, ByteArray> =
    withState(accountId, deviceId) { DirectMessageCipher(it, accountId, deviceId).send(messageId, routes, text, bundles, nowMillis) }

internal fun DeviceIdentityStore.receiveDirectMessage(accountId: String, deviceId: String, envelopeId: String,
    expected: DirectMessageRoute, wire: ByteArray, nowMillis: Long): ReceivedDirectMessage =
    withState(accountId, deviceId) { DirectMessageCipher(it, accountId, deviceId).receive(envelopeId, expected, wire, nowMillis) }

private val canonicalUuid = Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
private fun checkedUuid(id: String) { require(canonicalUuid.matches(id)) { "Invalid canonical identifier" } }
private fun DataOutputStream.uuid(id: String) {
    checkedUuid(id); val uuid = UUID.fromString(id); writeLong(uuid.mostSignificantBits); writeLong(uuid.leastSignificantBits)
}
private fun DataInputStream.uuid() = UUID(readLong(), readLong()).toString()
private fun DataOutputStream.blob(bytes: ByteArray, max: Int) { require(bytes.size in 1..max); writeInt(bytes.size); write(bytes) }
private fun DataInputStream.blob(max: Int): ByteArray {
    val size = readInt(); require(size in 1..max && size <= available())
    return ByteArray(size).also { readFully(it) }
}
