package com.airninja.protocol.secure

import com.southernstorm.noise.protocol.HandshakeState

object NoiseProtocol {
    const val NAME = "Noise_XX_25519_ChaChaPoly_SHA256"
}

enum class NoiseRole(val handshakeStateValue: Int) {
    INITIATOR(HandshakeState.INITIATOR),
    RESPONDER(HandshakeState.RESPONDER),
}
