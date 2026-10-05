// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.io.DataInputStream
import java.io.DataOutputStream
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.util.UUID

/** Private durable send intent; persist withState before issuing any HTTP prekey claim. */
internal class PreparedDirectMessage private constructor(
    val messageId: String, routes: List<DirectMessageRoute>, val text: String,
    claims: Map<String, String>
) {
    val routes: List<DirectMessageRoute> = java.util.Collections.unmodifiableList(routes.toList())
    val claimIds: Map<String, String> = java.util.Collections.unmodifiableMap(claims.toSortedMap())

    init {
        BridgeValues.id(messageId)
        require(this.routes.size in 1..16)
        val first = this.routes.first()
        require(this.routes == this.routes.sortedBy { it.recipientDeviceId })
        require(this.routes.map { it.recipientDeviceId }.toSet().size == this.routes.size)
        require(this.routes.all { it == first.copy(recipientDeviceId = it.recipientDeviceId) })
        require(claimIds.keys == this.routes.map { it.recipientDeviceId }.toSet())
        require(claimIds.values.toSet().size == claimIds.size)
        claimIds.values.forEach { BridgeValues.id(it) }
        DirectMessageCipher.encodeText(text).fill(0)
    }

    fun requiredClaimDeviceIds(state: DeviceKeyState): List<String> {
        val store = DeviceProtocolStore(state)
        return routes.map { it.recipientDeviceId }.filter {
            !store.containsSession(DeviceProtocolStore.deviceAddress(it))
        }
    }

    fun write(stream: DataOutputStream) {
        stream.writeUTF(messageId)
        stream.writeInt(routes.size)
        routes.forEach { it.write(stream) }
        val bytes = DirectMessageCipher.encodeText(text)
        try { stream.writeInt(bytes.size); stream.write(bytes) } finally { bytes.fill(0) }
        for (route in routes) stream.writeUTF(claimIds.getValue(route.recipientDeviceId))
    }

    companion object {
        fun prepare(state: DeviceKeyState, accountId: String, deviceId: String, messageId: String,
            routes: List<DirectMessageRoute>, text: String, nowMillis: Long): PreparedDirectMessage {
            BridgeValues.id(accountId); BridgeValues.id(deviceId); BridgeValues.id(messageId)
            require(routes.isNotEmpty())
            val sorted = routes.sortedBy { it.recipientDeviceId }
            val first = sorted.first()
            require(first.senderUserId == accountId && first.senderDeviceId == deviceId)
            require(nowMillis > 0 && first.expiresAtMillis > nowMillis) { "Message expired" }
            require(!state.outbox.containsKey(messageId)) { "Message already encrypted" }
            val existing = state.prepared[messageId]
            if (existing != null) {
                require(existing.routes == sorted && existing.text == text) { "Prepared message intent changed" }
                return existing
            }
            require(state.outbox.size + state.prepared.size < NativeMessageJournal.MAX_OUTBOX) { "Outgoing capacity exceeded" }
            val record = PreparedDirectMessage(messageId, sorted, text,
                sorted.associate { it.recipientDeviceId to UUID.randomUUID().toString() })
            state.prepared[messageId] = record
            return record
        }

        fun read(stream: DataInputStream): PreparedDirectMessage {
            val id = stream.readUTF()
            val count = stream.readInt().also { require(it in 1..16) }
            val routes = (1..count).map { DirectMessageRoute.read(stream) }
            val size = stream.readInt().also { require(it in 1..8192 && it <= stream.available()) }
            val bytes = ByteArray(size).also { stream.readFully(it) }
            val text = try {
                Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString()
            } finally { bytes.fill(0) }
            val claims = routes.associate { it.recipientDeviceId to stream.readUTF() }
            return PreparedDirectMessage(id, routes, text, claims)
        }
    }
}
