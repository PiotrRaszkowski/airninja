package com.airninja.protocol.message

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class ControlMessagesTest {

    @Test
    fun ackBuildsCoreAckEnvelopeReferencingOriginal() {
        //WHEN
        val ack = ControlMessages.ack(originalEnvelopeId = "env-1", ackId = "ack-1", sentAt = 1718600001000L)

        //THEN
        assertThat(ack.type).isEqualTo("core.ack")
        assertThat(ack.id).isEqualTo("ack-1")
        assertThat(ack.replyTo).isEqualTo("env-1")
    }

    @Test
    fun ackSerializesWithReplyToField() {
        //WHEN
        val encoded = EnvelopeCodec.encode(ControlMessages.ack("env-1", "ack-1", 0L))

        //THEN
        assertThat(encoded).contains("\"type\":\"core.ack\"")
        assertThat(encoded).contains("\"replyTo\":\"env-1\"")
    }
}
