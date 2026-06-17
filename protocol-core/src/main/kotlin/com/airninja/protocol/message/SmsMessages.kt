package com.airninja.protocol.message

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject

object SmsMessages {
    const val TYPE = "sms.message"

    private val json = Json { ignoreUnknownKeys = true }

    fun toEnvelope(message: SmsMessage, envelopeId: String, sentAt: Long): Envelope =
        Envelope(
            id = envelopeId,
            type = TYPE,
            ts = sentAt,
            payload = json.encodeToJsonElement(SmsMessage.serializer(), message).jsonObject,
        )

    fun fromEnvelope(envelope: Envelope): SmsMessage {
        require(envelope.type == TYPE) { "Not an $TYPE envelope: ${envelope.type}" }
        return json.decodeFromJsonElement(SmsMessage.serializer(), envelope.payload)
    }
}
