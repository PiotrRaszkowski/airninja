package com.airninja.protocol.message

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test
import java.io.File

class SmsMessagesTest {

    private val sample = SmsMessage(
        sender = "+15551234567",
        body = "Hello from Android",
        timestamp = 1718599999000L,
        messageId = "sms-42",
    )

    @Test
    fun toEnvelopeProducesSmsMessageEnvelopeThatRoundTrips() {
        //WHEN
        val envelope = SmsMessages.toEnvelope(sample, envelopeId = "env-1", sentAt = 1718600000000L)

        //THEN
        assertThat(envelope.type).isEqualTo("sms.message")
        assertThat(envelope.id).isEqualTo("env-1")
        assertThat(SmsMessages.fromEnvelope(envelope)).isEqualTo(sample)
    }

    @Test
    fun fromEnvelopeGivenWrongTypeThrows() {
        //GIVEN
        val envelope = Envelope(id = "x", type = "core.ping", ts = 0)

        //WHEN / THEN
        assertThatThrownBy { SmsMessages.fromEnvelope(envelope) }
            .isInstanceOf(IllegalArgumentException::class.java)
    }

    @Test
    fun fromEnvelopeDecodesSharedConformanceEnvelope() {
        //GIVEN
        val envelope = EnvelopeCodec.decode(loadSharedEnvelope())

        //WHEN
        val message = SmsMessages.fromEnvelope(envelope)

        //THEN
        assertThat(envelope.type).isEqualTo("sms.message")
        assertThat(message).isEqualTo(sample)
    }

    private fun loadSharedEnvelope(): String {
        val candidates = listOf(
            File("../shared/conformance/sms_envelope.json"),
            File("shared/conformance/sms_envelope.json"),
        )
        return candidates.first { it.exists() }.readText()
    }
}
