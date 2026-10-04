// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import android.util.Base64
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.time.Instant
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import org.signal.libsignal.protocol.state.KyberPreKeyRecord
import org.signal.libsignal.protocol.state.PreKeyRecord
import org.signal.libsignal.protocol.state.SignedPreKeyRecord

/** One process only. Private key/session bytes never cross the Flutter channel. */
internal class DeviceIdentityStore(private val context: Context) {
    fun initialize(accountId: String, deviceId: String): Map<String, Any> =
        withState(accountId, deviceId) { publicIdentity(it) }

    fun initializePreKeys(accountId: String, deviceId: String): Map<String, Any> =
        withState(accountId, deviceId) { state ->
            val now = System.currentTimeMillis()
            state.initializePreKeys(now)
            check(now < state.bundleExpiresAt()) { "Prekey bundle expired; verified rotation required" }
            val signed = SignedPreKeyRecord(state.signedPreKey!!)
            val kem = KyberPreKeyRecord(state.kemPreKey!!)
            publicIdentity(state) + ("bundle" to mapOf(
                "protocolVersion" to 2,
                "registrationId" to state.identity.registrationId,
                "identityPublicKeyBase64" to base64(state.identity.pair.publicKey.serialize()),
                "signedPrekeyId" to signed.id,
                "signedPrekeyPublicBase64" to base64(signed.keyPair.publicKey.serialize()),
                "signedPrekeySignatureBase64" to base64(signed.signature),
                "kemPrekeyId" to kem.id,
                "kemPrekeyPublicBase64" to base64(kem.keyPair.publicKey.serialize()),
                "kemPrekeySignatureBase64" to base64(kem.signature),
                "expiresAt" to Instant.ofEpochMilli(state.bundleExpiresAt()).toString(),
                "oneTimePrekeys" to state.preKeys.map { (id, bytes) ->
                    mapOf("keyId" to id, "publicKeyBase64" to base64(PreKeyRecord(bytes).keyPair.publicKey.serialize()))
                }
            ))
        }

    /** SDK mutations are staged in memory; exceptions discard them. Return only after a durable write. */
    internal fun <T> withState(accountId: String, deviceId: String, operation: (DeviceKeyState) -> T): T = synchronized(lock) {
        require(uuid.matches(accountId) && uuid.matches(deviceId)) { "Invalid identity scope" }
        val scope = "${accountId.lowercase()}/${deviceId.lowercase()}"
        val hash = MessageDigest.getInstance("SHA-256").digest(scope.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it.toInt() and 255) }
        val alias = "guffsuff.libsignal.identity.$hash"
        val directory = File(context.noBackupFilesDir, "libsignal-identities")
        check(directory.isDirectory || directory.mkdirs()) { "Identity storage unavailable" }
        val file = AtomicFile(File(directory, "$hash.bin"))
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val hasKey = keyStore.containsAlias(alias)
        val exists = file.baseFile.exists() || File(file.baseFile.path + ".bak").exists()
        check(hasKey == exists) { "Identity storage/key mismatch; explicit recovery required" }
        // Keep envelope version/AAD stable when migrating legacy version-1 plaintext records.
        val aad = "guffsuff/libsignal/identity/v1/$scope".toByteArray(Charsets.UTF_8)
        try {
            val key = if (exists) keyStore.getKey(alias, null) as SecretKey else {
                val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
                generator.init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    .setRandomizedEncryptionRequired(true)
                    .build())
                generator.generateKey()
            }
            val state = if (exists) {
                val encoded = file.openRead().use {
                    val bounded = ByteArray(DeviceKeyState.MAX_BYTES + 30)
                    var count = 0
                    while (count < bounded.size) {
                        val read = it.read(bounded, count, bounded.size - count)
                        if (read < 0) break
                        check(read > 0) { "Secure storage read failed" }; count += read
                    }
                    check(count in 30..(DeviceKeyState.MAX_BYTES + 29)) { "Invalid encrypted state record" }
                    bounded.copyOf(count)
                }
                check(encoded[0] == 1.toByte()) { "Unsupported encrypted state version" }
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, encoded.copyOfRange(1, 13)))
                cipher.updateAAD(aad)
                val plaintext = cipher.doFinal(encoded, 13, encoded.size - 13)
                try { DeviceKeyState.decode(plaintext) } finally { plaintext.fill(0) }
            } else DeviceKeyState(IdentityMaterial.create())
            val result = operation(state)
            val plaintext = state.encode()
            try {
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                cipher.init(Cipher.ENCRYPT_MODE, key)
                check(cipher.iv.size == 12) { "Unsupported storage nonce size" }
                cipher.updateAAD(aad)
                val encoded = byteArrayOf(1) + cipher.iv + cipher.doFinal(plaintext)
                val output = file.startWrite()
                try { output.write(encoded); output.fd.sync(); file.finishWrite(output) }
                catch (error: Throwable) { file.failWrite(output); throw error }
            } finally { plaintext.fill(0) }
            result
        } catch (error: Throwable) {
            // Never delete an existing/published identity on migration, callback or persistence failure.
            if (!exists) { file.delete(); keyStore.deleteEntry(alias) }
            throw error
        }
    }

    private fun publicIdentity(state: DeviceKeyState): Map<String, Any> = mapOf(
        "providerId" to "signalapp/libsignal",
        "providerVersion" to "0.104.0",
        "identityPublicKeyBase64" to base64(state.identity.pair.publicKey.serialize()),
        "registrationId" to state.identity.registrationId,
        // Protected sessions alone cannot enable sending without atomic outbox/history integration.
        "supportsDirectMessaging" to false
    )

    companion object {
        private val lock = Any()
        private val uuid = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
        private fun base64(bytes: ByteArray) = Base64.encodeToString(bytes, Base64.NO_WRAP)
    }
}
