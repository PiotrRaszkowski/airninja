package com.airninja.protocol.identity

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test

class DeviceIdentityTest {

    @Test
    fun generateProducesThirtyTwoByteKeysAndDeviceId() {
        //WHEN
        val identity = DeviceIdentity.generate()

        //THEN
        assertThat(identity.publicKey).hasSize(32)
        assertThat(identity.privateKey).hasSize(32)
        assertThat(identity.deviceId).hasSize(52)
    }

    @Test
    fun generateProducesDistinctIdentities() {
        //WHEN
        val first = DeviceIdentity.generate()
        val second = DeviceIdentity.generate()

        //THEN
        assertThat(first.deviceId).isNotEqualTo(second.deviceId)
    }

    @Test
    fun publicKeyGetterReturnsDefensiveCopy() {
        //GIVEN
        val identity = DeviceIdentity.generate()

        //WHEN
        identity.publicKey[0] = (identity.publicKey[0] + 1).toByte()

        //THEN
        assertThat(identity.publicKey).isEqualTo(identity.publicKey)
        assertThat(DeviceId.fromPublicKey(identity.publicKey)).isEqualTo(identity.deviceId)
    }

    @Test
    fun fromRawKeysGivenWrongPrivateKeySizeThrows() {
        //GIVEN
        val shortPrivate = ByteArray(16)
        val publicKey = ByteArray(32)

        //WHEN / THEN
        assertThatThrownBy { DeviceIdentity.fromRawKeys(shortPrivate, publicKey) }
            .isInstanceOf(IllegalArgumentException::class.java)
    }
}
