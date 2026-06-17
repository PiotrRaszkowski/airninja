package com.airninja.protocol

object Hex {
    fun decode(hex: String): ByteArray {
        require(hex.length % 2 == 0) { "Hex string must have even length" }
        return ByteArray(hex.length / 2) { index ->
            val offset = index * 2
            hex.substring(offset, offset + 2).toInt(16).toByte()
        }
    }

    fun encode(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it) }
}
