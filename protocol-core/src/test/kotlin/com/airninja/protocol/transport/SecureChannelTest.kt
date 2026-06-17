package com.airninja.protocol.transport

import com.airninja.protocol.framing.Frame
import com.airninja.protocol.framing.FrameCodec
import com.airninja.protocol.identity.DeviceIdentity
import com.airninja.protocol.secure.NoiseRole
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import java.io.PipedInputStream
import java.io.PipedOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class SecureChannelTest {

    @Test
    fun handshakeOverStreamsEstablishesMatchingChannelAndTransfersFrames() {
        //GIVEN
        val alice = DeviceIdentity.generate()
        val bob = DeviceIdentity.generate()
        val initiatorOutput = PipedOutputStream()
        val responderInput = PipedInputStream(initiatorOutput)
        val responderOutput = PipedOutputStream()
        val initiatorInput = PipedInputStream(responderOutput)
        val executor = Executors.newFixedThreadPool(2)

        //WHEN
        val initiatorChannel = executor.submit<SecureChannel> {
            SecureChannel.handshake(NoiseRole.INITIATOR, alice, initiatorInput, initiatorOutput)
        }
        val responderChannel = executor.submit<SecureChannel> {
            SecureChannel.handshake(NoiseRole.RESPONDER, bob, responderInput, responderOutput)
        }
        val initiator = initiatorChannel.get(5, TimeUnit.SECONDS)
        val responder = responderChannel.get(5, TimeUnit.SECONDS)

        initiator.send(FrameCodec.encode(Frame.Control("sms from android".toByteArray())))
        val receivedByResponder = FrameCodec.decode(responder.receive()) as Frame.Control
        responder.send(FrameCodec.encode(Frame.Control("ack from macos".toByteArray())))
        val receivedByInitiator = FrameCodec.decode(initiator.receive()) as Frame.Control

        //THEN
        assertThat(initiator.sas).isEqualTo(responder.sas)
        assertThat(initiator.remoteStaticPublicKey).isEqualTo(bob.publicKey)
        assertThat(responder.remoteStaticPublicKey).isEqualTo(alice.publicKey)
        assertThat(receivedByResponder.payload).isEqualTo("sms from android".toByteArray())
        assertThat(receivedByInitiator.payload).isEqualTo("ack from macos".toByteArray())

        executor.shutdownNow()
    }
}
