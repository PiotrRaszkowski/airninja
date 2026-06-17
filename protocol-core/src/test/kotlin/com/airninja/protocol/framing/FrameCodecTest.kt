package com.airninja.protocol.framing

import com.airninja.protocol.Hex
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test

class FrameCodecTest {

    @Test
    fun encodeGivenControlFrameProducesLengthPrefixedFrame() {
        //GIVEN
        val payload = "hi".toByteArray(Charsets.UTF_8)

        //WHEN
        val encoded = FrameCodec.encode(Frame.Control(payload))

        //THEN
        assertThat(Hex.encode(encoded)).isEqualTo("00000003016869")
    }

    @Test
    fun encodeGivenDataFrameProducesSubHeaderAndChunk() {
        //GIVEN
        val frame = Frame.Data(streamId = 1001, sequence = 1, isFinal = true, chunk = "hello".toByteArray())

        //WHEN
        val encoded = FrameCodec.encode(frame)

        //THEN
        assertThat(Hex.encode(encoded)).isEqualTo("0000001302000003e900000000000000010168656c6c6f")
    }

    @Test
    fun decodeGivenEncodedControlFrameRoundTripsPayload() {
        //GIVEN
        val payload = "round-trip".toByteArray(Charsets.UTF_8)
        val encoded = FrameCodec.encode(Frame.Control(payload))

        //WHEN
        val decoded = FrameCodec.decode(encoded)

        //THEN
        assertThat(decoded).isInstanceOf(Frame.Control::class.java)
        assertThat((decoded as Frame.Control).payload).isEqualTo(payload)
    }

    @Test
    fun decodeGivenEncodedDataFrameRoundTripsAllFields() {
        //GIVEN
        val original = Frame.Data(streamId = 42, sequence = 7, isFinal = false, chunk = byteArrayOf(1, 2, 3))
        val encoded = FrameCodec.encode(original)

        //WHEN
        val decoded = FrameCodec.decode(encoded) as Frame.Data

        //THEN
        assertThat(decoded.streamId).isEqualTo(42)
        assertThat(decoded.sequence).isEqualTo(7)
        assertThat(decoded.isFinal).isFalse()
        assertThat(decoded.chunk).isEqualTo(byteArrayOf(1, 2, 3))
    }

    @Test
    fun decodeGivenWrongLengthPrefixThrows() {
        //GIVEN
        val corrupted = Hex.decode("00000099016869")

        //WHEN / THEN
        assertThatThrownBy { FrameCodec.decode(corrupted) }
            .isInstanceOf(IllegalArgumentException::class.java)
    }

    @Test
    fun decodeGivenUnknownFrameTypeThrows() {
        //GIVEN
        val unknownType = Hex.decode("000000017f")

        //WHEN / THEN
        assertThatThrownBy { FrameCodec.decode(unknownType) }
            .isInstanceOf(IllegalArgumentException::class.java)
    }
}
