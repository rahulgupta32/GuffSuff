// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import org.signal.libsignal.protocol.ecc.ECKeyPair
import org.signal.libsignal.protocol.kem.KEMKeyPair
import org.signal.libsignal.protocol.kem.KEMKeyType
import org.signal.libsignal.protocol.state.KyberPreKeyRecord
import org.signal.libsignal.protocol.state.PreKeyRecord
import org.signal.libsignal.protocol.state.SignedPreKeyRecord

/** Bounded native working state. Never return this object or its encoding to Dart. */
internal class DeviceKeyState(val identity: IdentityMaterial) {
    var bundleCreatedAt = 0L
    var signedPreKey: ByteArray? = null
    var kemPreKey: ByteArray? = null
    val preKeys = sortedMapOf<Int, ByteArray>()
    val sessions = sortedMapOf<String, ByteArray>()
    val trustedIdentities = sortedMapOf<String, ByteArray>()
    val usedKemBaseKeys = sortedSetOf<String>()
    val outbox = sortedMapOf<String, JournalRecord>()
    val inbox = sortedMapOf<String, JournalRecord>()

    fun initializePreKeys(now: Long) {
        if (signedPreKey != null) return
        require(now > 0 && now <= Long.MAX_VALUE - BUNDLE_LIFETIME)
        check(kemPreKey == null && preKeys.isEmpty()) { "Incomplete key state" }
        val signedPair = ECKeyPair.generate()
        val signedSignature = identity.pair.privateKey.calculateSignature(signedPair.publicKey.serialize())
        val kemPair = KEMKeyPair.generate(KEMKeyType.KYBER_1024)
        val kemSignature = identity.pair.privateKey.calculateSignature(kemPair.publicKey.serialize())
        // These mutations are staged; DeviceIdentityStore persists the entire state before returning.
        signedPreKey = SignedPreKeyRecord(1, now, signedPair, signedSignature).serialize()
        kemPreKey = KyberPreKeyRecord(1, now, kemPair, kemSignature).serialize()
        for (id in 1..100) preKeys[id] = PreKeyRecord(id, ECKeyPair.generate()).serialize()
        bundleCreatedAt = now
    }

    fun bundleExpiresAt(): Long = Math.addExact(bundleCreatedAt, BUNDLE_LIFETIME)

    fun encode(): ByteArray {
        val output = BoundedOutput()
        DataOutputStream(output).use { stream ->
            stream.writeInt(3)
            val identityBytes = identity.encode()
            try { stream.blob(identityBytes, 4096) } finally { identityBytes.fill(0) }
            stream.writeLong(bundleCreatedAt)
            stream.blob(signedPreKey ?: byteArrayOf(), 4096, allowEmpty = true)
            stream.blob(kemPreKey ?: byteArrayOf(), 16384, allowEmpty = true)
            require(preKeys.size <= 100)
            stream.writeInt(preKeys.size)
            for ((id, record) in preKeys) { require(id in 1..100); stream.writeInt(id); stream.blob(record, 4096) }
            stream.recordMap(sessions, 128, 65536)
            stream.recordMap(trustedIdentities, 128, 33)
            require(usedKemBaseKeys.size <= 1000)
            stream.writeInt(usedKemBaseKeys.size)
            for (entry in usedKemBaseKeys) { require(kemUse.matches(entry)); stream.writeUTF(entry) }
            NativeMessageJournal.write(stream, outbox, incoming = false)
            NativeMessageJournal.write(stream, inbox, incoming = true)
        }
        require(output.size() <= MAX_BYTES) { "Secure state capacity exceeded" }
        return output.toByteArray()
    }

    /** Stop before allocating beyond the total encrypted-record budget. */
    private class BoundedOutput : ByteArrayOutputStream() {
        override fun write(value: Int) {
            require(size() < MAX_BYTES) { "Secure state capacity exceeded" }
            super.write(value)
        }
        override fun write(bytes: ByteArray, offset: Int, length: Int) {
            require(length >= 0 && length <= MAX_BYTES - size()) { "Secure state capacity exceeded" }
            super.write(bytes, offset, length)
        }
    }

    companion object {
        const val MAX_BYTES = 1024 * 1024
        const val BUNDLE_LIFETIME = 28L * 86400000
        private val address = Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/1$")
        private val kemUse = Regex("^1:1:[0-9a-f]{66}$")

        fun decode(bytes: ByteArray): DeviceKeyState {
            require(bytes.size in 13..MAX_BYTES)
            DataInputStream(ByteArrayInputStream(bytes)).use { stream ->
                val version = stream.readInt()
                when (version) {
                    1 -> return DeviceKeyState(IdentityMaterial.decode(bytes)) // Preserve the original identity.
                    2, 3 -> Unit
                    else -> throw IllegalArgumentException("Unsupported secure state version")
                }
                val identityBytes = stream.blob(4096)
                val state = try { DeviceKeyState(IdentityMaterial.decode(identityBytes)) } finally { identityBytes.fill(0) }
                state.bundleCreatedAt = stream.readLong()
                state.signedPreKey = stream.blob(4096, true).takeIf { it.isNotEmpty() }
                state.kemPreKey = stream.blob(16384, true).takeIf { it.isNotEmpty() }
                repeat(stream.count(100)) {
                    val id = stream.readInt()
                    require(id in 1..100 && !state.preKeys.containsKey(id))
                    val record = stream.blob(4096)
                    require(PreKeyRecord(record).id == id)
                    state.preKeys[id] = record
                }
                state.sessions.putAll(stream.recordMap(128, 65536))
                state.trustedIdentities.putAll(stream.recordMap(128, 33))
                require(state.trustedIdentities.values.all { it.size == 33 && it[0] == 5.toByte() })
                repeat(stream.count(1000)) {
                    val entry = stream.readUTF()
                    require(kemUse.matches(entry) && state.usedKemBaseKeys.add(entry))
                }
                if (version == 3) {
                    state.outbox.putAll(NativeMessageJournal.read(stream, incoming = false))
                    state.inbox.putAll(NativeMessageJournal.read(stream, incoming = true))
                }
                require(stream.available() == 0) { "Trailing secure state data" }
                state.validateBundle()
                return state
            }
        }

        private fun DataOutputStream.blob(bytes: ByteArray, max: Int, allowEmpty: Boolean = false) {
            require(bytes.size in (if (allowEmpty) 0 else 1)..max)
            writeInt(bytes.size); write(bytes)
        }

        private fun DataInputStream.blob(max: Int, allowEmpty: Boolean = false): ByteArray {
            val size = readInt()
            require(size in (if (allowEmpty) 0 else 1)..max && size <= available()) { "Invalid secure record length" }
            return ByteArray(size).also { readFully(it) }
        }

        private fun DataInputStream.count(max: Int): Int = readInt().also { require(it in 0..max) }

        private fun DataOutputStream.recordMap(records: Map<String, ByteArray>, max: Int, recordMax: Int) {
            require(records.size <= max); writeInt(records.size)
            for ((key, bytes) in records) { require(address.matches(key)); writeUTF(key); blob(bytes, recordMax) }
        }

        private fun DataInputStream.recordMap(max: Int, recordMax: Int): Map<String, ByteArray> {
            val records = sortedMapOf<String, ByteArray>()
            repeat(count(max)) {
                val key = readUTF(); require(address.matches(key) && !records.containsKey(key))
                records[key] = blob(recordMax)
            }
            return records
        }
    }

    private fun validateBundle() {
        if (signedPreKey == null) {
            require(bundleCreatedAt == 0L && kemPreKey == null && preKeys.isEmpty() && usedKemBaseKeys.isEmpty())
            return
        }
        require(bundleCreatedAt > 0 && bundleCreatedAt <= Long.MAX_VALUE - BUNDLE_LIFETIME && kemPreKey != null)
        val signed = SignedPreKeyRecord(signedPreKey!!)
        val kem = KyberPreKeyRecord(kemPreKey!!)
        require(signed.id == 1 && kem.id == 1 && signed.timestamp == bundleCreatedAt && kem.timestamp == bundleCreatedAt)
        val publicIdentity = identity.pair.publicKey.publicKey
        require(publicIdentity.verifySignature(signed.keyPair.publicKey.serialize(), signed.signature)) { "Invalid signed prekey" }
        require(publicIdentity.verifySignature(kem.keyPair.publicKey.serialize(), kem.signature)) { "Invalid KEM prekey" }
    }
}
