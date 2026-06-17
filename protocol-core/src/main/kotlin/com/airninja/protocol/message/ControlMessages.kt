package com.airninja.protocol.message

object ControlMessages {
    const val ACK = "core.ack"

    fun ack(originalEnvelopeId: String, ackId: String, sentAt: Long): Envelope =
        Envelope(
            id = ackId,
            type = ACK,
            replyTo = originalEnvelopeId,
            ts = sentAt,
        )
}
