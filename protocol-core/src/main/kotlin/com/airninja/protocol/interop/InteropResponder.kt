package com.airninja.protocol.interop

import com.airninja.protocol.framing.Frame
import com.airninja.protocol.framing.FrameCodec
import com.airninja.protocol.identity.DeviceIdentity
import com.airninja.protocol.secure.NoiseRole
import com.airninja.protocol.transport.SecureChannel
import java.net.ServerSocket

private const val DEFAULT_PORT = 38520

fun main(args: Array<String>) {
    val port = args.firstOrNull()?.toInt() ?: DEFAULT_PORT
    val identity = DeviceIdentity.generate()
    ServerSocket(port).use { server ->
        println("LISTENING $port")
        System.out.flush()
        server.accept().use { socket ->
            val channel = SecureChannel.handshake(
                NoiseRole.RESPONDER,
                identity,
                socket.getInputStream(),
                socket.getOutputStream(),
            )
            val received = FrameCodec.decode(channel.receive()) as Frame.Control
            val text = String(received.payload)
            println("SAS=${channel.sas}")
            println("REMOTE=${channel.remoteStaticPublicKey.toHex()}")
            println("RECV=$text")
            channel.send(FrameCodec.encode(Frame.Control("ack:$text".toByteArray())))
            System.out.flush()
        }
    }
}

private fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }
