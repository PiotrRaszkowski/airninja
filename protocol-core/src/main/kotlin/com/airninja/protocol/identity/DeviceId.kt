package com.airninja.protocol.identity

import com.airninja.protocol.crypto.Base32
import com.airninja.protocol.crypto.Sha256

object DeviceId {
    private const val LENGTH = 52

    fun fromPublicKey(staticPublicKey: ByteArray): String {
        require(staticPublicKey.isNotEmpty()) { "Static public key must not be empty" }
        return Base32.encodeLowerNoPadding(Sha256.hash(staticPublicKey)).take(LENGTH)
    }
}
