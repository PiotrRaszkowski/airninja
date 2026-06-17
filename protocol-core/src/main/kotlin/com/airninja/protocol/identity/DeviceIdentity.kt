package com.airninja.protocol.identity

import org.bouncycastle.crypto.generators.X25519KeyPairGenerator
import org.bouncycastle.crypto.params.X25519KeyGenerationParameters
import org.bouncycastle.crypto.params.X25519PrivateKeyParameters
import org.bouncycastle.crypto.params.X25519PublicKeyParameters
import java.security.SecureRandom

class DeviceIdentity private constructor(
    private val privateKeyBytes: ByteArray,
    private val publicKeyBytes: ByteArray,
) {
    val publicKey: ByteArray
        get() = publicKeyBytes.copyOf()

    val privateKey: ByteArray
        get() = privateKeyBytes.copyOf()

    val deviceId: String = DeviceId.fromPublicKey(publicKeyBytes)

    companion object {
        private const val KEY_SIZE = 32

        fun generate(random: SecureRandom = SecureRandom()): DeviceIdentity {
            val generator = X25519KeyPairGenerator()
            generator.init(X25519KeyGenerationParameters(random))
            val pair = generator.generateKeyPair()
            val privateKey = (pair.private as X25519PrivateKeyParameters).encoded
            val publicKey = (pair.public as X25519PublicKeyParameters).encoded
            return DeviceIdentity(privateKey, publicKey)
        }

        fun fromRawKeys(privateKey: ByteArray, publicKey: ByteArray): DeviceIdentity {
            require(privateKey.size == KEY_SIZE) { "X25519 private key must be $KEY_SIZE bytes" }
            require(publicKey.size == KEY_SIZE) { "X25519 public key must be $KEY_SIZE bytes" }
            return DeviceIdentity(privateKey.copyOf(), publicKey.copyOf())
        }
    }
}
