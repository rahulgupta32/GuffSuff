// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.junit.After
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Actual AndroidKeyStore/filesystem tests. Every scope is an isolated generated fixture. */
@RunWith(AndroidJUnit4::class)
class DeviceIdentityStoreTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val scopes = mutableListOf<Pair<String, String>>()

    private fun scope(): Pair<String, String> =
        (UUID.randomUUID().toString() to UUID.randomUUID().toString()).also { scopes.add(it) }

    private fun hash(scope: Pair<String, String>): String = MessageDigest.getInstance("SHA-256")
        .digest("${scope.first.lowercase()}/${scope.second.lowercase()}".toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it.toInt() and 255) }

    private fun record(scope: Pair<String, String>) =
        File(context.noBackupFilesDir, "libsignal-identities/${hash(scope)}.bin")

    private fun alias(scope: Pair<String, String>) = "guffsuff.libsignal.identity.${hash(scope)}"

    private fun initialize(scope: Pair<String, String>) =
        DeviceIdentityStore(context).initialize(scope.first, scope.second)

    @After fun removeOnlyGeneratedFixtures() {
        val keys = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        for (scope in scopes) {
            val file = record(scope)
            file.delete()
            File(file.path + ".bak").delete()
            File(file.path + ".new").delete()
            keys.deleteEntry(alias(scope))
        }
    }

    @Test fun restoresSameIdentityAcrossStoreInstancesAndUuidCase() {
        val scope = scope()
        val original = initialize(scope)
        assertEquals(original, initialize(scope))
        assertEquals(original, initialize(scope.first.uppercase() to scope.second.uppercase()))
        assertEquals(false, original["supportsDirectMessaging"])
        assertEquals(setOf("providerId", "providerVersion", "identityPublicKeyBase64", "registrationId", "supportsDirectMessaging"), original.keys)
        assertTrue(record(scope).isFile)
        val wrappingKey = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.getKey(alias(scope), null)
        assertNull("Wrapping key must not be exportable", wrappingKey.encoded)
    }

    @Test fun independentAccountAndDeviceScopesDoNotShareIdentity() {
        val first = scope()
        val otherAccount = (UUID.randomUUID().toString() to first.second).also { scopes.add(it) }
        val otherDevice = (first.first to UUID.randomUUID().toString()).also { scopes.add(it) }
        val publicKey = initialize(first)["identityPublicKeyBase64"]
        assertNotEquals(publicKey, initialize(otherAccount)["identityPublicKeyBase64"])
        assertNotEquals(publicKey, initialize(otherDevice)["identityPublicKeyBase64"])
    }

    @Test fun concurrentInitializationConvergesOnOneIdentity() {
        val scope = scope()
        val executor = Executors.newFixedThreadPool(8)
        try {
            val futures = executor.invokeAll((1..8).map { Callable { initialize(scope) } }, 30, TimeUnit.SECONDS)
            val results = futures.map { it.get(5, TimeUnit.SECONDS) }
            assertTrue(results.all { it == results.first() })
            assertEquals(results.first(), initialize(scope))
        } finally { executor.shutdownNow() }
    }

    @Test fun tamperedCiphertextFailsWithoutReplacingIdentity() {
        val scope = scope()
        val original = initialize(scope)
        val file = record(scope)
        val valid = file.readBytes()
        val tampered = valid.copyOf().apply { this[lastIndex] = (this[lastIndex].toInt() xor 1).toByte() }
        file.writeBytes(tampered)
        assertThrows(Exception::class.java) { initialize(scope) }
        assertArrayEquals(tampered, file.readBytes())
        file.writeBytes(valid)
        assertEquals(original, initialize(scope))
    }

    @Test fun missingWrappingKeyFailsWithoutReplacingRecord() {
        val scope = scope()
        initialize(scope)
        val bytes = record(scope).readBytes()
        KeyStore.getInstance("AndroidKeyStore").apply { load(null); deleteEntry(alias(scope)) }
        assertThrows(IllegalStateException::class.java) { initialize(scope) }
        assertArrayEquals(bytes, record(scope).readBytes())
    }

    @Test fun missingRecordFailsWithoutReplacingWrappingKey() {
        val scope = scope()
        initialize(scope)
        assertTrue(record(scope).delete())
        assertThrows(IllegalStateException::class.java) { initialize(scope) }
        assertFalse(record(scope).exists())
        assertTrue(KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.containsAlias(alias(scope)))
    }

    @Test fun interruptedAtomicFileBackupRestoresOriginalIdentity() {
        val scope = scope()
        val original = initialize(scope)
        val file = record(scope)
        assertTrue(file.renameTo(File(file.path + ".bak")))
        file.writeBytes(byteArrayOf(1, 2, 3))
        assertEquals(original, initialize(scope))
        assertFalse(File(file.path + ".bak").exists())
    }

    @Test fun invalidScopeFailsBeforeCreatingStorage() {
        assertThrows(IllegalArgumentException::class.java) {
            DeviceIdentityStore(context).initialize("../invalid", UUID.randomUUID().toString())
        }
    }
}
