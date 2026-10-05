// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.time.Instant
import java.util.Base64
import java.util.UUID
import org.junit.Assert.*
import org.junit.Test
import org.signal.libsignal.protocol.state.*

class BridgeValuesTest {
    private val now = System.currentTimeMillis()
    private fun id() = UUID.randomUUID().toString()
    private fun encoded(bytes: ByteArray) = Base64.getEncoder().encodeToString(bytes)
    private fun claim(): MutableMap<String, Any> {
        val state = DeviceKeyState(IdentityMaterial.create()).apply { initializePreKeys(now) }
        val signed = SignedPreKeyRecord(state.signedPreKey!!); val kem = KyberPreKeyRecord(state.kemPreKey!!)
        val key = PreKeyRecord(state.preKeys.getValue(1))
        return mutableMapOf("deviceId" to id(), "protocolVersion" to 2, "registrationId" to state.identity.registrationId,
            "identityPublicKeyBase64" to encoded(state.identity.pair.publicKey.serialize()), "signedPrekeyId" to signed.id,
            "signedPrekeyPublicBase64" to encoded(signed.keyPair.publicKey.serialize()), "signedPrekeySignatureBase64" to encoded(signed.signature),
            "kemPrekeyId" to kem.id, "kemPrekeyPublicBase64" to encoded(kem.keyPair.publicKey.serialize()), "kemPrekeySignatureBase64" to encoded(kem.signature),
            "expiresAt" to Instant.ofEpochMilli(now + 60000).toString(), "oneTimePrekeyId" to key.id,
            "oneTimePrekeyPublicBase64" to encoded(key.keyPair.publicKey.serialize()))
    }
    private fun route(): DirectMessageRoute = DirectMessageRoute(id(), id(), id(), id(), id(), now, now + 60000)

    @Test fun actualSignedKemClaimParsesToNativeBundleWithUuidAddressSlotOne() {
        val input = claim(); val (device, bundle) = BridgeValues.claim(input, now)
        assertEquals(input["deviceId"], device); assertEquals(1, bundle.deviceId)
        assertEquals(input["registrationId"], bundle.registrationId)
        assertEquals(input["identityPublicKeyBase64"], encoded(bundle.identityKey.serialize()))
        assertEquals(input["signedPrekeyPublicBase64"], encoded(bundle.signedPreKey.serialize()))
        assertEquals(input["kemPrekeyPublicBase64"], encoded(bundle.kyberPreKey.serialize()))
        assertEquals(input["oneTimePrekeyPublicBase64"], encoded(bundle.preKey!!.serialize()))
    }

    @Test fun invalidClassicalAndKemSignaturesAreRejectedAtBoundary() {
        val original = claim()
        for (field in listOf("signedPrekeySignatureBase64", "kemPrekeySignatureBase64")) {
            val bytes = Base64.getDecoder().decode(original[field] as String)
            bytes[0] = (bytes[0].toInt() xor 1).toByte()
            assertThrows(IllegalArgumentException::class.java) { BridgeValues.claim(original + (field to encoded(bytes)), now) }
        }
    }

    @Test fun privateUnexpectedLegacyMissingAndWrongTypedFieldsFail() {
        val original = claim()
        val invalid = listOf(original + ("privateKey" to "never accepted"), original + ("protocolVersion" to 1),
            original + ("registrationId" to 1.0), original + ("oneTimePrekeyId" to -1),
            original - "oneTimePrekeyPublicBase64", original + ("kemPrekeyId" to Long.MAX_VALUE))
        for (value in invalid) assertThrows(Exception::class.java) { BridgeValues.claim(value, now) }
    }

    @Test fun expiredOverlongInvalidCalendarAndNonUtcClaimsFail() {
        val original = claim()
        for (expiry in listOf(Instant.ofEpochMilli(now).toString(), Instant.ofEpochMilli(now + 31L * 86400000).toString(),
            "2026-02-30T00:00:00Z", "2026-10-05T23:59:60Z", "2026-10-05T00:00:00+00:00")) {
            assertThrows(Exception::class.java) { BridgeValues.claim(original + ("expiresAt" to expiry), now) }
        }
    }

    @Test fun malformedEncodingsAndInvalidKemMaterialFailWithoutFallback() {
        val original = claim()
        for ((field, invalid) in listOf("identityPublicKeyBase64" to ((original["identityPublicKeyBase64"] as String) + "\n"),
            "oneTimePrekeyPublicBase64" to encoded(ByteArray(33)), "kemPrekeyPublicBase64" to encoded(byteArrayOf(1, 2, 3)),
            "signedPrekeySignatureBase64" to "%%%")) {
            assertThrows(Exception::class.java) { BridgeValues.claim(original + (field to invalid), now) }
        }
    }

    @Test fun routeScopeTypesAndCollectionBoundsAreStrictAndRoundTripExact() {
        val route = route(); val input = BridgeValues.routeMap(route)
        assertEquals(route, BridgeValues.route(input))
        assertEquals(route, BridgeValues.route(input + ("protocolVersion" to 2L)))
        for (invalid in listOf(input + ("createdAtMillis" to now.toDouble()), input + ("privateState" to byteArrayOf(1)),
            input + ("protocolVersion" to 1), input + ("recipientUserId" to route.senderUserId))) {
            assertThrows(IllegalArgumentException::class.java) { BridgeValues.route(invalid) }
        }
        assertThrows(IllegalArgumentException::class.java) { BridgeValues.id("../scope") }
        assertThrows(IllegalArgumentException::class.java) { BridgeValues.list(List(17) { 1 }, 0, 16) }
        assertThrows(IllegalArgumentException::class.java) { BridgeValues.objectMap(mapOf(1 to "value"), setOf("id")) }
    }
}
