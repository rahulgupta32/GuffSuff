// SPDX-License-Identifier: AGPL-3.0-only
package com.guffsuff.mobile.crypto

import java.util.UUID
import org.signal.libsignal.protocol.*
import org.signal.libsignal.protocol.ecc.ECPublicKey
import org.signal.libsignal.protocol.groups.state.SenderKeyRecord
import org.signal.libsignal.protocol.state.*

/** SDK callbacks mutate a staged state. Only a surrounding protected transaction makes it durable. */
internal class DeviceProtocolStore(private val state: DeviceKeyState) : SignalProtocolStore {
    override fun getIdentityKeyPair() = state.identity.pair
    override fun getLocalRegistrationId() = state.identity.registrationId
    override fun getIdentity(address: SignalProtocolAddress): IdentityKey? = state.trustedIdentities[key(address)]?.let { IdentityKey(it) }
    override fun isTrustedIdentity(address: SignalProtocolAddress, identityKey: IdentityKey, direction: IdentityKeyStore.Direction): Boolean =
        state.trustedIdentities[key(address)]?.contentEquals(identityKey.serialize()) ?: true
    override fun saveIdentity(address: SignalProtocolAddress, identityKey: IdentityKey): IdentityKeyStore.IdentityChange {
        val name = key(address)
        val bytes = identityKey.serialize()
        val old = state.trustedIdentities[name]
        check(old == null || old.contentEquals(bytes)) { "Peer identity change requires explicit verification" }
        check(old != null || state.trustedIdentities.size < 128) { "Peer identity capacity exceeded" }
        state.trustedIdentities[name] = bytes
        return IdentityKeyStore.IdentityChange.NEW_OR_UNCHANGED
    }
    override fun loadPreKey(id: Int): PreKeyRecord = state.preKeys[id]?.let { PreKeyRecord(it) } ?: throw InvalidKeyIdException("One-time prekey unavailable")
    override fun storePreKey(id: Int, record: PreKeyRecord) {
        require(id in 1..100 && record.id == id)
        val bytes = record.serialize()
        check(state.preKeys[id]?.contentEquals(bytes) == true) { "Prekey replacement/replenishment requires a separate flow" }
    }
    override fun containsPreKey(id: Int) = state.preKeys.containsKey(id)
    override fun removePreKey(id: Int) { state.preKeys.remove(id) }
    override fun loadSignedPreKey(id: Int): SignedPreKeyRecord = state.signedPreKey?.let { SignedPreKeyRecord(it) }?.takeIf { it.id == id }
        ?: throw InvalidKeyIdException("Signed prekey unavailable")
    override fun loadSignedPreKeys(): List<SignedPreKeyRecord> = state.signedPreKey?.let { listOf(SignedPreKeyRecord(it)) } ?: emptyList()
    override fun containsSignedPreKey(id: Int) = state.signedPreKey?.let { SignedPreKeyRecord(it).id == id } ?: false
    override fun storeSignedPreKey(id: Int, record: SignedPreKeyRecord) {
        check(id == record.id && state.signedPreKey?.contentEquals(record.serialize()) == true) { "Signed prekey rotation unavailable" }
    }
    override fun removeSignedPreKey(id: Int) { throw UnsupportedOperationException("Signed prekey retirement unavailable") }
    override fun loadKyberPreKey(id: Int): KyberPreKeyRecord = state.kemPreKey?.let { KyberPreKeyRecord(it) }?.takeIf { it.id == id }
        ?: throw InvalidKeyIdException("KEM prekey unavailable")
    override fun loadKyberPreKeys(): List<KyberPreKeyRecord> = state.kemPreKey?.let { listOf(KyberPreKeyRecord(it)) } ?: emptyList()
    override fun containsKyberPreKey(id: Int) = state.kemPreKey?.let { KyberPreKeyRecord(it).id == id } ?: false
    override fun storeKyberPreKey(id: Int, record: KyberPreKeyRecord) {
        check(id == record.id && state.kemPreKey?.contentEquals(record.serialize()) == true) { "KEM prekey rotation unavailable" }
    }
    override fun markKyberPreKeyUsed(id: Int, signedId: Int, baseKey: ECPublicKey) {
        require(containsKyberPreKey(id) && containsSignedPreKey(signedId))
        val entry = "$id:$signedId:" + baseKey.serialize().joinToString("") { "%02x".format(it.toInt() and 255) }
        if (state.usedKemBaseKeys.contains(entry)) throw ReusedBaseKeyException()
        check(state.usedKemBaseKeys.size < 1000) { "KEM replay record capacity exceeded" }
        state.usedKemBaseKeys.add(entry)
    }
    override fun loadSession(address: SignalProtocolAddress): SessionRecord = state.sessions[key(address)]?.let { SessionRecord(it) } ?: SessionRecord()
    override fun loadExistingSessions(addresses: List<SignalProtocolAddress>): List<SessionRecord> = addresses.map {
        if (!containsSession(it)) throw NoSessionException("Session unavailable")
        loadSession(it).also { record -> if (!record.hasSenderChain()) throw NoSessionException("Session unavailable") }
    }
    override fun storeSession(address: SignalProtocolAddress, record: SessionRecord) {
        val name = key(address)
        check(state.sessions.containsKey(name) || state.sessions.size < 128) { "Session capacity exceeded" }
        val bytes = record.serialize(); require(bytes.size in 1..65536)
        state.sessions[name] = bytes
    }
    override fun containsSession(address: SignalProtocolAddress) = state.sessions[key(address)]?.let { SessionRecord(it).hasSenderChain() } ?: false
    override fun getSubDeviceSessions(name: String): List<Int> =
        if (containsSession(deviceAddress(name))) listOf(1) else emptyList()
    override fun deleteSession(address: SignalProtocolAddress) { state.sessions.remove(key(address)) }
    override fun deleteAllSessions(name: String) { deleteSession(deviceAddress(name)) }
    override fun storeSenderKey(sender: SignalProtocolAddress, distributionId: UUID, record: SenderKeyRecord) {
        throw UnsupportedOperationException("Group provider unavailable")
    }
    override fun loadSenderKey(sender: SignalProtocolAddress, distributionId: UUID): SenderKeyRecord? {
        throw UnsupportedOperationException("Group provider unavailable")
    }

    companion object {
        private val uuid = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
        // Every app device UUID is a separate libsignal address name, with numeric slot 1.
        fun deviceAddress(deviceId: String): SignalProtocolAddress {
            require(uuid.matches(deviceId)); return SignalProtocolAddress(deviceId.lowercase(), 1)
        }
        private fun key(address: SignalProtocolAddress): String {
            require(uuid.matches(address.name) && address.deviceId == 1)
            return "${address.name.lowercase()}/1"
        }
    }
}
