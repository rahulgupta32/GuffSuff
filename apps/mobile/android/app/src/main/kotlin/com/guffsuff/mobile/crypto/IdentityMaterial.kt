// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import org.signal.libsignal.protocol.IdentityKeyPair
import org.signal.libsignal.protocol.util.KeyHelper

/** Native private material. Only publicResult may cross the Flutter channel. */
internal class IdentityMaterial(val pair: IdentityKeyPair, val registrationId: Int) {
    init { require(registrationId in 1..16380) }

    fun encode(): ByteArray {
        val serialized = pair.serialize()
        try {
            val output = ByteArrayOutputStream()
            DataOutputStream(output).use {
                it.writeInt(1)
                it.writeInt(registrationId)
                it.writeInt(serialized.size)
                it.write(serialized)
            }
            return output.toByteArray()
        } finally { serialized.fill(0) }
    }

    companion object {
        fun create() = IdentityMaterial(IdentityKeyPair.generate(), KeyHelper.generateRegistrationId(false))

        fun decode(bytes: ByteArray): IdentityMaterial {
            require(bytes.size in 13..4096) { "Invalid identity record" }
            DataInputStream(ByteArrayInputStream(bytes)).use {
                require(it.readInt() == 1) { "Unsupported identity record version" }
                val registrationId = it.readInt()
                require(registrationId in 1..16380) { "Invalid registration ID" }
                val length = it.readInt()
                require(length in 1..1024 && it.available() == length) { "Invalid identity record length" }
                val serialized = ByteArray(length)
                it.readFully(serialized)
                try { return IdentityMaterial(IdentityKeyPair(serialized), registrationId) }
                finally { serialized.fill(0) }
            }
        }
    }
}
