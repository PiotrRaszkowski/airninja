package com.airninja.protocol.secure

import com.airninja.protocol.identity.DeviceIdentity
import com.southernstorm.noise.protocol.DHState
import com.southernstorm.noise.protocol.HandshakeState

class NoiseHandshake private constructor(private val handshakeState: HandshakeState) {

    fun start() = handshakeState.start()

    fun needsWrite(): Boolean = handshakeState.action == HandshakeState.WRITE_MESSAGE

    fun needsRead(): Boolean = handshakeState.action == HandshakeState.READ_MESSAGE

    val isHandshakeFinished: Boolean
        get() = handshakeState.action == HandshakeState.SPLIT

    fun writeMessage(payload: ByteArray = ByteArray(0)): ByteArray {
        val buffer = ByteArray(MESSAGE_BUFFER_SIZE)
        val length = handshakeState.writeMessage(buffer, 0, payload, 0, payload.size)
        return buffer.copyOf(length)
    }

    fun readMessage(message: ByteArray): ByteArray {
        val payload = ByteArray(MESSAGE_BUFFER_SIZE)
        val length = handshakeState.readMessage(message, 0, message.size, payload, 0)
        return payload.copyOf(length)
    }

    fun split(): TransportPair = TransportPair(handshakeState.split())

    val handshakeHash: ByteArray
        get() = handshakeState.handshakeHash

    val localStaticPublicKey: ByteArray
        get() = readPublicKey(handshakeState.localKeyPair)

    val remoteStaticPublicKey: ByteArray
        get() = readPublicKey(handshakeState.remotePublicKey)

    fun destroy() = handshakeState.destroy()

    private fun readPublicKey(dhState: DHState): ByteArray {
        val publicKey = ByteArray(dhState.publicKeyLength)
        dhState.getPublicKey(publicKey, 0)
        return publicKey
    }

    companion object {
        private const val MESSAGE_BUFFER_SIZE = 4096

        fun create(role: NoiseRole, identity: DeviceIdentity): NoiseHandshake {
            val handshakeState = HandshakeState(NoiseProtocol.NAME, role.handshakeStateValue)
            handshakeState.localKeyPair.setPrivateKey(identity.privateKey, 0)
            return NoiseHandshake(handshakeState)
        }
    }
}
