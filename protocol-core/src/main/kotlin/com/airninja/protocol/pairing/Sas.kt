package com.airninja.protocol.pairing

import com.airninja.protocol.crypto.Sha256
import java.nio.ByteBuffer

object Sas {
    private const val PREFIX = "AIRNINJA-SAS"
    private const val MODULO = 1_000_000
    private const val DIGITS = 6
    private const val UNSIGNED_INT_MASK = 0xFFFFFFFFL

    fun derive(handshakeHash: ByteArray): String {
        val digest = Sha256.hash(PREFIX.toByteArray(Charsets.US_ASCII) + handshakeHash)
        val value = ByteBuffer.wrap(digest, 0, Int.SIZE_BYTES).int.toLong() and UNSIGNED_INT_MASK
        return (value % MODULO).toString().padStart(DIGITS, '0')
    }
}
