package com.airninja.protocol.crypto

object Base32 {
    private const val ALPHABET = "abcdefghijklmnopqrstuvwxyz234567"
    private const val BITS_PER_SYMBOL = 5
    private const val BYTE_BITS = 8
    private const val SYMBOL_MASK = 0x1F

    fun encodeLowerNoPadding(data: ByteArray): String {
        val builder = StringBuilder()
        var buffer = 0
        var bitsLeft = 0
        for (byte in data) {
            buffer = (buffer shl BYTE_BITS) or (byte.toInt() and 0xFF)
            bitsLeft += BYTE_BITS
            while (bitsLeft >= BITS_PER_SYMBOL) {
                val index = (buffer shr (bitsLeft - BITS_PER_SYMBOL)) and SYMBOL_MASK
                builder.append(ALPHABET[index])
                bitsLeft -= BITS_PER_SYMBOL
            }
        }
        if (bitsLeft > 0) {
            val index = (buffer shl (BITS_PER_SYMBOL - bitsLeft)) and SYMBOL_MASK
            builder.append(ALPHABET[index])
        }
        return builder.toString()
    }
}
