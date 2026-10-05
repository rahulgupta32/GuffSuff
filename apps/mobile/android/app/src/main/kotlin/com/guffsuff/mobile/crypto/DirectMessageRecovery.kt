// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.security.MessageDigest
import java.util.Base64

/** Only use within protected withState transactions. No SDK encrypt/decrypt callbacks run here. */
internal class DirectMessageRecovery(private val state: DeviceKeyState, private val accountId: String, private val deviceId: String) {
    init { BridgeValues.id(accountId); BridgeValues.id(deviceId) }
    private data class Outgoing(val message: ReceivedDirectMessage, val batch: Map<String, ByteArray>, val fingerprint: ByteArray, val intent: ByteArray)

    fun pending(conversationId: String): List<Map<String, Any>> {
        BridgeValues.id(conversationId)
        return state.outbox.filterValues { !it.isAccepted }.mapNotNull { (id, record) ->
            val recovered = outgoing(id, record)
            try {
                if (recovered.message.route.conversationId != conversationId) null else mapOf(
                    "messageId" to id, "route" to BridgeValues.routeMap(recovered.message.route),
                    "batchFingerprintBase64" to base64(recovered.fingerprint),
                    "deviceEnvelopes" to recovered.batch.map { (device, bytes) -> mapOf(
                        "recipientDeviceId" to device, "opaquePayloadBase64" to base64(bytes)) })
            } finally { recovered.intent.fill(0) }
        }
    }

    /** Caller must first validate the authenticated server's acceptance for this exact batch. */
    fun accepted(messageId: String, envelopeId: String, fingerprint: ByteArray) {
        BridgeValues.id(messageId); BridgeValues.id(envelopeId); require(fingerprint.size == 32)
        val record = state.outbox[messageId] ?: error("Unknown outgoing message")
        val recovered = outgoing(messageId, record)
        try {
            require(MessageDigest.isEqual(recovered.fingerprint, fingerprint)) { "Batch acceptance mismatch" }
            val previous = state.acceptedEnvelopes[messageId]
            require(previous == null || previous == envelopeId) { "Acceptance identifier changed" }
            require(state.acceptedEnvelopes.none { (id, envelope) -> id != messageId && envelope == envelopeId })
            NativeMessageJournal(state).markAccepted(messageId, recovered.intent)
            state.acceptedEnvelopes[messageId] = envelopeId
        } finally { recovered.intent.fill(0) }
    }

    /** Bounded current journal history, sorted by timestamp/direction/record ID. No retention paging yet. */
    fun history(conversationId: String): List<Map<String, Any?>> {
        BridgeValues.id(conversationId)
        val result = mutableListOf<Map<String, Any?>>()
        for ((id, record) in state.outbox) {
            val recovered = outgoing(id, record)
            try {
                val message = recovered.message
                if (message.route.conversationId == conversationId) result.add(historyRow(
                    id, "outgoing", message, record.isAccepted, state.acceptedEnvelopes[id]))
            } finally { recovered.intent.fill(0) }
        }
        for ((id, record) in state.inbox) {
            val bytes = record.history()
            val message = try { DirectMessageCipher.decodePayload(bytes) } finally { bytes.fill(0) }
            require(record.isIncoming && message.route.recipientUserId == accountId && message.route.recipientDeviceId == deviceId)
            if (message.route.conversationId == conversationId) result.add(historyRow(id, "incoming", message, true, id))
        }
        return result.sortedWith(compareBy({ (it.getValue("route") as Map<*, *>)["createdAtMillis"] as Long },
            { it.getValue("direction") as String }, { it.getValue("recordId") as String }))
    }

    private fun historyRow(id: String, direction: String, message: ReceivedDirectMessage, accepted: Boolean,
        envelope: String?): Map<String, Any?> = mapOf("recordId" to id, "direction" to direction,
        "messageId" to message.messageId, "route" to BridgeValues.routeMap(message.route), "text" to message.text,
        "isAccepted" to accepted, "serverEnvelopeId" to envelope)

    private fun outgoing(id: String, record: JournalRecord): Outgoing {
        val history = record.history()
        val message = try { DirectMessageCipher.decodePayload(history) } finally { history.fill(0) }
        require(!record.isIncoming && message.messageId == id && message.route.senderUserId == accountId && message.route.senderDeviceId == deviceId)
        val encoded = record.ciphertext()
        val batch = DirectMessageCipher.decodeBatch(encoded)
        require(batch.containsKey(message.route.recipientDeviceId))
        val routes = batch.keys.map { message.route.copy(recipientDeviceId = it) }
        // Outgoing local history always contains the first route of the sorted original inventory.
        require(message.route == routes.first())
        val text = DirectMessageCipher.encodeText(message.text)
        val intent = try { DirectMessageCipher.canonicalIntent(id, routes, text) } finally { text.fill(0) }
        try {
            NativeMessageJournal(state).outgoing(id, intent) { error("Recovery must not encrypt") }
            val hash = MessageDigest.getInstance("SHA-256")
            hash.update("guffsuff/direct-outbox/v1\u0000".toByteArray(Charsets.UTF_8))
            val binding = ByteArrayOutputStream()
            DataOutputStream(binding).use { stream ->
                stream.writeUTF(id); message.route.write(stream); stream.writeInt(encoded.size); stream.write(encoded)
            }
            return Outgoing(message, batch, hash.digest(binding.toByteArray()), intent)
        } catch (error: Throwable) { intent.fill(0); throw error }
    }

    private fun base64(bytes: ByteArray) = Base64.getEncoder().encodeToString(bytes)
}
