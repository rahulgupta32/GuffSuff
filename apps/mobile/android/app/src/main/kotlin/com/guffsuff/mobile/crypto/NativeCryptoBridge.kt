// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.time.Instant
import java.util.Base64
import org.signal.libsignal.protocol.IdentityKey
import org.signal.libsignal.protocol.ecc.ECPublicKey
import org.signal.libsignal.protocol.kem.KEMPublicKey
import org.signal.libsignal.protocol.state.PreKeyBundle

/** Codec-compatible public/ciphertext/verified-message values only; never export private state. */
internal class NativeCryptoBridge(private val store: DeviceIdentityStore) {
    fun execute(method: String, arguments: Any?, nowMillis: Long = System.currentTimeMillis()): Map<String, Any> {
        require(method in METHODS)
        val fields = when (method) {
            "sendDirectMessage" -> setOf("accountId", "deviceId", "messageId", "routes", "text", "claimedBundles")
            "receiveDirectMessage" -> setOf("accountId", "deviceId", "envelopeId", "route", "opaquePayloadBase64")
            else -> setOf("accountId", "deviceId")
        }
        val args = BridgeValues.objectMap(arguments, fields)
        val account = BridgeValues.id(args["accountId"]); val device = BridgeValues.id(args["deviceId"])
        return when (method) {
            "initializeIdentity" -> store.initialize(account, device)
            "initializePreKeys" -> store.initializePreKeys(account, device)
            "sendDirectMessage" -> {
                val message = BridgeValues.id(args["messageId"])
                val text = args["text"] as? String ?: throw IllegalArgumentException("Text required")
                require(text.isNotBlank() && text.length <= 8192 && text.toByteArray(Charsets.UTF_8).size <= 8192)
                val routes = BridgeValues.list(args["routes"], 1, 16).map { BridgeValues.route(it) }
                val claims = BridgeValues.list(args["claimedBundles"], 0, 16)
                val bundles = sortedMapOf<String, PreKeyBundle>()
                for (claim in claims) {
                    val (id, bundle) = BridgeValues.claim(claim, nowMillis)
                    require(!bundles.containsKey(id)); bundles[id] = bundle
                }
                require(routes.all { it.senderUserId == account && it.senderDeviceId == device })
                require(routes.map { it.recipientDeviceId }.toSet().size == routes.size)
                require(bundles.keys.all { id -> routes.any { it.recipientDeviceId == id } })
                val batch = store.sendDirectMessage(account, device, message, routes, text, bundles, nowMillis)
                mapOf("messageId" to message, "protocolVersion" to 2, "deviceEnvelopes" to batch.map { (id, bytes) ->
                    mapOf("recipientDeviceId" to id, "opaquePayloadBase64" to Base64.getEncoder().encodeToString(bytes))
                })
            }
            "receiveDirectMessage" -> {
                val envelope = BridgeValues.id(args["envelopeId"])
                val route = BridgeValues.route(args["route"])
                require(route.recipientUserId == account && route.recipientDeviceId == device)
                val ciphertext = BridgeValues.bytes(args["opaquePayloadBase64"], 13, 65536)
                val received = store.receiveDirectMessage(account, device, envelope, route, ciphertext, nowMillis)
                mapOf("messageId" to received.messageId, "route" to BridgeValues.routeMap(received.route), "text" to received.text)
            }
            else -> error("Unsupported operation")
        }
    }

    companion object {
        val METHODS = setOf("initializeIdentity", "initializePreKeys", "sendDirectMessage", "receiveDirectMessage")
    }
}

/** Strict boundary checks precede protected storage; SDK parsing/signatures are not mocked. */
internal object BridgeValues {
    private val uuid = Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
    private val utcMillis = Regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{1,3})?Z$")
    private val routeFields = setOf("conversationId", "senderUserId", "senderDeviceId", "recipientUserId",
        "recipientDeviceId", "createdAtMillis", "expiresAtMillis", "protocolVersion")
    private val claimFields = setOf("deviceId", "protocolVersion", "registrationId", "identityPublicKeyBase64",
        "signedPrekeyId", "signedPrekeyPublicBase64", "signedPrekeySignatureBase64", "kemPrekeyId",
        "kemPrekeyPublicBase64", "kemPrekeySignatureBase64", "expiresAt", "oneTimePrekeyId", "oneTimePrekeyPublicBase64")

    fun objectMap(value: Any?, fields: Set<String>): Map<*, *> {
        val map = value as? Map<*, *> ?: throw IllegalArgumentException("Object required")
        require(map.keys == fields) { "Unexpected object fields" }
        return map
    }
    fun id(value: Any?): String = (value as? String)?.also { require(uuid.matches(it)) }
        ?: throw IllegalArgumentException("Canonical identifier required")
    fun integer(value: Any?, min: Long, max: Long): Long {
        val result = when (value) { is Int -> value.toLong(); is Long -> value; else -> throw IllegalArgumentException("Integer required") }
        require(result in min..max); return result
    }
    fun list(value: Any?, min: Int, max: Int): List<*> = (value as? List<*>)?.also { require(it.size in min..max) }
        ?: throw IllegalArgumentException("List required")
    fun bytes(value: Any?, min: Int, max: Int, curve: Boolean = false): ByteArray {
        val text = value as? String ?: throw IllegalArgumentException("Public encoding required")
        require(text.length <= ((max + 2) / 3) * 4)
        val bytes = Base64.getDecoder().decode(text)
        require(bytes.size in min..max && Base64.getEncoder().encodeToString(bytes) == text)
        require(!curve || (bytes.size == 33 && bytes[0] == 5.toByte()))
        return bytes
    }
    fun route(value: Any?): DirectMessageRoute {
        val map = objectMap(value, routeFields)
        return DirectMessageRoute(id(map["conversationId"]), id(map["senderUserId"]), id(map["senderDeviceId"]),
            id(map["recipientUserId"]), id(map["recipientDeviceId"]),
            integer(map["createdAtMillis"], 1, Long.MAX_VALUE), integer(map["expiresAtMillis"], 1, Long.MAX_VALUE),
            integer(map["protocolVersion"], 2, 2).toInt())
    }
    fun routeMap(route: DirectMessageRoute): Map<String, Any> = mapOf(
        "conversationId" to route.conversationId, "senderUserId" to route.senderUserId,
        "senderDeviceId" to route.senderDeviceId, "recipientUserId" to route.recipientUserId,
        "recipientDeviceId" to route.recipientDeviceId, "createdAtMillis" to route.createdAtMillis,
        "expiresAtMillis" to route.expiresAtMillis, "protocolVersion" to route.protocolVersion)

    fun claim(value: Any?, nowMillis: Long): Pair<String, PreKeyBundle> {
        val map = objectMap(value, claimFields)
        val device = id(map["deviceId"])
        integer(map["protocolVersion"], 2, 2)
        val expiryText = map["expiresAt"] as? String ?: throw IllegalArgumentException("Expiry required")
        require(utcMillis.matches(expiryText))
        val instant = Instant.parse(expiryText)
        require(instant.toString().take(19) == expiryText.take(19)) { "Invalid calendar timestamp" }
        val expires = instant.toEpochMilli()
        require(nowMillis > 0 && nowMillis <= Long.MAX_VALUE - 30L * 86400000)
        require(expires > nowMillis && expires <= nowMillis + 30L * 86400000)
        val identityBytes = bytes(map["identityPublicKeyBase64"], 33, 33, true)
        val signedBytes = bytes(map["signedPrekeyPublicBase64"], 33, 33, true)
        val kemBytes = bytes(map["kemPrekeyPublicBase64"], 1, 4096)
        val identity = IdentityKey(identityBytes)
        val signed = ECPublicKey(signedBytes)
        val kem = KEMPublicKey(kemBytes)
        require(identity.serialize().contentEquals(identityBytes) && signed.serialize().contentEquals(signedBytes) && kem.serialize().contentEquals(kemBytes))
        val signedSignature = bytes(map["signedPrekeySignatureBase64"], 64, 64)
        val kemSignature = bytes(map["kemPrekeySignatureBase64"], 64, 64)
        require(identity.publicKey.verifySignature(signedBytes, signedSignature)) { "Invalid signed prekey" }
        require(identity.publicKey.verifySignature(kemBytes, kemSignature)) { "Invalid KEM prekey" }
        val oneTime = ECPublicKey(bytes(map["oneTimePrekeyPublicBase64"], 33, 33, true))
        fun keyId(name: String) = integer(map[name], 0, Int.MAX_VALUE.toLong()).toInt()
        return device to PreKeyBundle(integer(map["registrationId"], 1, 16380).toInt(), 1,
            keyId("oneTimePrekeyId"), oneTime, keyId("signedPrekeyId"), signed, signedSignature,
            identity, keyId("kemPrekeyId"), kem, kemSignature)
    }
}
