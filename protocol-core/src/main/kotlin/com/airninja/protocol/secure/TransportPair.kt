package com.airninja.protocol.secure

import com.southernstorm.noise.protocol.CipherStatePair

class TransportPair internal constructor(private val cipherStatePair: CipherStatePair) {
    private val sender = cipherStatePair.sender
    private val receiver = cipherStatePair.receiver

    private val tagLength = sender.macLength

    fun encrypt(plaintext: ByteArray): ByteArray {
        val ciphertext = ByteArray(plaintext.size + tagLength)
        val length = sender.encryptWithAd(null, plaintext, 0, ciphertext, 0, plaintext.size)
        return ciphertext.copyOf(length)
    }

    fun decrypt(ciphertext: ByteArray): ByteArray {
        val plaintext = ByteArray(ciphertext.size)
        val length = receiver.decryptWithAd(null, ciphertext, 0, plaintext, 0, ciphertext.size)
        return plaintext.copyOf(length)
    }

    fun destroy() = cipherStatePair.destroy()
}
