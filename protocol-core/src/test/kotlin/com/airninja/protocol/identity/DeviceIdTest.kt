package com.airninja.protocol.identity

import com.airninja.protocol.Hex
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test

class DeviceIdTest {

    @Test
    fun fromPublicKeyGivenKnownKeyReturnsExpectedDeviceId() {
        //GIVEN
        val publicKey = Hex.decode("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")

        //WHEN
        val deviceId = DeviceId.fromPublicKey(publicKey)

        //THEN
        assertThat(deviceId).isEqualTo("mmg42klgyqzwneiskrelxms3j72bfje4omw3fsflyg4fqg6xcdoq")
    }

    @Test
    fun fromPublicKeyGivenAnyKeyReturnsFiftyTwoCharacterId() {
        //GIVEN
        val publicKey = ByteArray(32) { it.toByte() }

        //WHEN
        val deviceId = DeviceId.fromPublicKey(publicKey)

        //THEN
        assertThat(deviceId).hasSize(52)
    }

    @Test
    fun fromPublicKeyGivenEmptyKeyThrows() {
        //GIVEN
        val publicKey = ByteArray(0)

        //WHEN / THEN
        assertThatThrownBy { DeviceId.fromPublicKey(publicKey) }
            .isInstanceOf(IllegalArgumentException::class.java)
    }
}
