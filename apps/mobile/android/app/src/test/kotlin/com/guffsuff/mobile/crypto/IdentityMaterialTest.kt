// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import org.junit.Assert.*
import org.junit.Test

class IdentityMaterialTest {
    @Test fun nativeIdentitySurvivesSerialization() {
        val original = IdentityMaterial.create()
        val encoded = original.encode()
        try {
            val restored = IdentityMaterial.decode(encoded)
            assertEquals(original.registrationId, restored.registrationId)
            assertArrayEquals(original.pair.publicKey.serialize(), restored.pair.publicKey.serialize())
            val message = "गफसफ native identity test".toByteArray(Charsets.UTF_8)
            val signature = restored.pair.privateKey.calculateSignature(message)
            assertTrue(original.pair.publicKey.publicKey.verifySignature(message, signature))
            assertFalse(original.pair.publicKey.publicKey.verifySignature(message + byteArrayOf(1), signature))
        } finally { encoded.fill(0) }
    }

    @Test fun independentlyGeneratedIdentitiesDiffer() {
        assertFalse(IdentityMaterial.create().pair.publicKey.serialize()
            .contentEquals(IdentityMaterial.create().pair.publicKey.serialize()))
    }

    @Test fun unsupportedOrTruncatedRecordsFailClosed() {
        val encoded = IdentityMaterial.create().encode()
        try {
            val wrongVersion = encoded.copyOf().apply { this[3] = 2 }
            assertThrows(IllegalArgumentException::class.java) { IdentityMaterial.decode(wrongVersion) }
            assertThrows(IllegalArgumentException::class.java) { IdentityMaterial.decode(encoded.copyOf(encoded.size - 1)) }
            assertThrows(IllegalArgumentException::class.java) { IdentityMaterial.decode(encoded + byteArrayOf(1)) }
        } finally { encoded.fill(0) }
    }
}
