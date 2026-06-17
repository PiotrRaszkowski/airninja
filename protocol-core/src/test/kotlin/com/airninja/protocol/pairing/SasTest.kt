package com.airninja.protocol.pairing

import com.airninja.protocol.Hex
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class SasTest {

    @Test
    fun deriveGivenKnownHandshakeHashReturnsExpectedSas() {
        //GIVEN
        val handshakeHash = Hex.decode("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

        //WHEN
        val sas = Sas.derive(handshakeHash)

        //THEN
        assertThat(sas).isEqualTo("124507")
    }

    @Test
    fun deriveAlwaysReturnsSixDigits() {
        //GIVEN
        val handshakeHash = ByteArray(32)

        //WHEN
        val sas = Sas.derive(handshakeHash)

        //THEN
        assertThat(sas).hasSize(6)
        assertThat(sas).containsOnlyDigits()
    }
}
