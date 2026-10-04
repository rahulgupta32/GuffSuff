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
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** One process only. No plaintext private key is written to disk or returned to Dart. */
internal class DeviceIdentityStore(private val context: Context) {
    fun initialize(accountId: String, deviceId: String): Map<String, Any> = synchronized(lock) {
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
        // AtomicFile's openRead restores an interrupted write backup when present.
        val exists = file.baseFile.exists() || File(file.baseFile.path + ".bak").exists()
        check(hasKey == exists) { "Identity storage/key mismatch; explicit recovery required" }
        val aad = "guffsuff/libsignal/identity/v1/$scope".toByteArray(Charsets.UTF_8)
        val material: IdentityMaterial
        if (exists) {
            val key = keyStore.getKey(alias, null) as SecretKey
            val encoded = file.openRead().use {
                val bounded = ByteArray(4097)
                var count = 0
                while (count < bounded.size) {
                    val read = it.read(bounded, count, bounded.size - count)
                    if (read < 0) break
                    count += read
                }
                check(count in 30..4096) { "Invalid encrypted identity record" }
                bounded.copyOf(count)
            }
            check(encoded[0] == 1.toByte()) { "Unsupported encrypted identity version" }
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, encoded.copyOfRange(1, 13)))
            cipher.updateAAD(aad)
            val plaintext = cipher.doFinal(encoded, 13, encoded.size - 13)
            try { material = IdentityMaterial.decode(plaintext) } finally { plaintext.fill(0) }
        } else {
            val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            generator.init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .setRandomizedEncryptionRequired(true)
                .build())
            var plaintext: ByteArray? = null
            try {
                val key = generator.generateKey()
                material = IdentityMaterial.create()
                val record = material.encode()
                plaintext = record
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                cipher.init(Cipher.ENCRYPT_MODE, key)
                check(cipher.iv.size == 12) { "Unsupported storage nonce size" }
                cipher.updateAAD(aad)
                val encoded = byteArrayOf(1) + cipher.iv + cipher.doFinal(record)
                val output = file.startWrite()
                try { output.write(encoded); output.fd.sync(); file.finishWrite(output) }
                catch (error: Throwable) { file.failWrite(output); throw error }
            } catch (error: Throwable) {
                // This is an unpublished, brand-new identity. Remove only its failed initialization.
                file.delete()
                keyStore.deleteEntry(alias)
                throw error
            } finally { plaintext?.fill(0) }
        }
        mapOf(
            "providerId" to "signalapp/libsignal",
            "providerVersion" to "0.104.0",
            "identityPublicKeyBase64" to Base64.encodeToString(material.pair.publicKey.serialize(), Base64.NO_WRAP),
            "registrationId" to material.registrationId,
            // Identity persistence alone cannot enable the composer or establish sessions.
            "supportsDirectMessaging" to false
        )
    }

    companion object {
        private val lock = Any()
        private val uuid = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
    }
}
