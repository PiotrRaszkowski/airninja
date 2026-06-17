package com.airninja.protocol.crypto

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class Base32Test {

    @Test
    fun encodeLowerNoPaddingGivenEmptyInputReturnsEmptyString() {
        //GIVEN
        val input = ByteArray(0)

        //WHEN
        val result = Base32.encodeLowerNoPadding(input)

        //THEN
        assertThat(result).isEmpty()
    }

    @Test
    fun encodeLowerNoPaddingGivenRfc4648VectorsReturnsLowercaseUnpadded() {
        //GIVEN / WHEN / THEN
        assertThat(encode("f")).isEqualTo("my")
        assertThat(encode("fo")).isEqualTo("mzxq")
        assertThat(encode("foo")).isEqualTo("mzxw6")
        assertThat(encode("foob")).isEqualTo("mzxw6yq")
        assertThat(encode("fooba")).isEqualTo("mzxw6ytb")
        assertThat(encode("foobar")).isEqualTo("mzxw6ytboi")
    }

    private fun encode(text: String): String =
        Base32.encodeLowerNoPadding(text.toByteArray(Charsets.US_ASCII))
}
