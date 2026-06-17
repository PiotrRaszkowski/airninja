package com.airninja.protocol.message

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class EnvelopeCodecTest {

    @Test
    fun encodeGivenPingEnvelopeOmitsNullReplyToAndKeepsFieldOrder() {
        //GIVEN
        val envelope = Envelope(id = "00000000-0000-4000-8000-000000000000", type = "core.ping", ts = 0)

        //WHEN
        val encoded = EnvelopeCodec.encode(envelope)

        //THEN
        assertThat(encoded).isEqualTo(
            "{\"v\":1,\"id\":\"00000000-0000-4000-8000-000000000000\",\"type\":\"core.ping\",\"ts\":0,\"payload\":{}}"
        )
    }

    @Test
    fun encodeGivenReplyToIncludesReplyToField() {
        //GIVEN
        val envelope = Envelope(id = "a", type = "core.ack", replyTo = "b", ts = 5)

        //WHEN
        val encoded = EnvelopeCodec.encode(envelope)

        //THEN
        assertThat(encoded).contains("\"replyTo\":\"b\"")
    }

    @Test
    fun decodeGivenEncodedEnvelopeRoundTrips() {
        //GIVEN
        val original = Envelope(id = "id-1", type = "sms.message", ts = 1718600000000L)

        //WHEN
        val decoded = EnvelopeCodec.decode(EnvelopeCodec.encode(original))

        //THEN
        assertThat(decoded).isEqualTo(original)
    }

    @Test
    fun decodeGivenUnknownFieldsIgnoresThem() {
        //GIVEN
        val json = "{\"v\":1,\"id\":\"id-2\",\"type\":\"core.ping\",\"ts\":0,\"payload\":{},\"future\":true}"

        //WHEN
        val decoded = EnvelopeCodec.decode(json)

        //THEN
        assertThat(decoded.id).isEqualTo("id-2")
        assertThat(decoded.type).isEqualTo("core.ping")
    }
}
