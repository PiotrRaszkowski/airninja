package com.airninja.protocol.transport

import com.airninja.protocol.identity.DeviceIdentity
import com.airninja.protocol.pairing.Sas
import com.airninja.protocol.secure.NoiseHandshake
import com.airninja.protocol.secure.NoiseRole
import com.airninja.protocol.secure.TransportPair
import java.io.InputStream
import java.io.OutputStream

class SecureChannel internal constructor(
    private val transport: TransportPair,
    val handshakeHash: ByteArray,
    val remoteStaticPublicKey: ByteArray,
    private val input: InputStream,
    private val output: OutputStream,
) {
    val sas: String
        get() = Sas.derive(handshakeHash)

    fun send(frame: ByteArray) {
        StreamFraming.writeFrame(output, transport.encrypt(frame))
    }

    fun receive(): ByteArray = transport.decrypt(StreamFraming.readFrame(input))

    companion object {
        fun handshake(
            role: NoiseRole,
            identity: DeviceIdentity,
            input: InputStream,
            output: OutputStream,
        ): SecureChannel {
            val handshake = NoiseHandshake.create(role, identity)
            handshake.start()
            while (!handshake.isHandshakeFinished) {
                if (handshake.needsWrite()) {
                    StreamFraming.writeFrame(output, handshake.writeMessage())
                } else {
                    handshake.readMessage(StreamFraming.readFrame(input))
                }
            }
            val handshakeHash = handshake.handshakeHash
            val remoteStaticPublicKey = handshake.remoteStaticPublicKey
            return SecureChannel(handshake.split(), handshakeHash, remoteStaticPublicKey, input, output)
        }
    }
}
