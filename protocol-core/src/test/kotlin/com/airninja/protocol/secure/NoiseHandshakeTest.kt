package com.airninja.protocol.secure

import com.airninja.protocol.identity.DeviceIdentity
import com.airninja.protocol.pairing.Sas
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test
import java.security.GeneralSecurityException

class NoiseHandshakeTest {

    @Test
    fun xxHandshakeDerivesEqualHandshakeHashAndSas() {
        //GIVEN
        val session = performXxHandshake()

        //WHEN
        val initiatorHash = session.initiator.handshakeHash
        val responderHash = session.responder.handshakeHash

        //THEN
        assertThat(initiatorHash).isEqualTo(responderHash)
        assertThat(Sas.derive(initiatorHash)).isEqualTo(Sas.derive(responderHash))
    }

    @Test
    fun xxHandshakeExchangesStaticKeysForPinning() {
        //GIVEN
        val session = performXxHandshake()

        //WHEN / THEN
        assertThat(session.initiator.localStaticPublicKey).isEqualTo(session.alice.publicKey)
        assertThat(session.initiator.remoteStaticPublicKey).isEqualTo(session.bob.publicKey)
        assertThat(session.responder.remoteStaticPublicKey).isEqualTo(session.alice.publicKey)
    }

    @Test
    fun transportEncryptsAndDecryptsBothDirections() {
        //GIVEN
        val session = performXxHandshake()
        val initiatorTransport = session.initiator.split()
        val responderTransport = session.responder.split()

        //WHEN
        val fromInitiator = initiatorTransport.encrypt("sms from android".toByteArray())
        val fromResponder = responderTransport.encrypt("ack from macos".toByteArray())

        //THEN
        assertThat(responderTransport.decrypt(fromInitiator)).isEqualTo("sms from android".toByteArray())
        assertThat(initiatorTransport.decrypt(fromResponder)).isEqualTo("ack from macos".toByteArray())
    }

    @Test
    fun transportRejectsTamperedCiphertext() {
        //GIVEN
        val session = performXxHandshake()
        val initiatorTransport = session.initiator.split()
        val responderTransport = session.responder.split()
        val ciphertext = initiatorTransport.encrypt("secret".toByteArray())

        //WHEN
        val tampered = ciphertext.copyOf()
        tampered[tampered.size - 1] = (tampered[tampered.size - 1].toInt() xor 0x01).toByte()

        //THEN
        assertThatThrownBy { responderTransport.decrypt(tampered) }
            .isInstanceOf(GeneralSecurityException::class.java)
    }

    private fun performXxHandshake(): EstablishedSession {
        val alice = DeviceIdentity.generate()
        val bob = DeviceIdentity.generate()
        val initiator = NoiseHandshake.create(NoiseRole.INITIATOR, alice)
        val responder = NoiseHandshake.create(NoiseRole.RESPONDER, bob)
        initiator.start()
        responder.start()
        responder.readMessage(initiator.writeMessage())
        initiator.readMessage(responder.writeMessage())
        responder.readMessage(initiator.writeMessage())
        return EstablishedSession(alice, bob, initiator, responder)
    }

    private class EstablishedSession(
        val alice: DeviceIdentity,
        val bob: DeviceIdentity,
        val initiator: NoiseHandshake,
        val responder: NoiseHandshake,
    )
}
