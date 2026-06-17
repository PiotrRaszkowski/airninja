package com.airninja.protocol.crypto

import java.security.MessageDigest

object Sha256 {
    fun hash(data: ByteArray): ByteArray =
        MessageDigest.getInstance("SHA-256").digest(data)
}
