package com.airninja.protocol.message

import kotlinx.serialization.json.Json

object EnvelopeCodec {
    private val json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
        encodeDefaults = true
    }

    fun encode(envelope: Envelope): String = json.encodeToString(Envelope.serializer(), envelope)

    fun encodeToBytes(envelope: Envelope): ByteArray = encode(envelope).toByteArray(Charsets.UTF_8)

    fun decode(text: String): Envelope = json.decodeFromString(Envelope.serializer(), text)

    fun decodeFromBytes(bytes: ByteArray): Envelope = decode(bytes.toString(Charsets.UTF_8))
}
