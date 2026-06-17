package com.airninja.protocol.message

import com.airninja.protocol.Protocol
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

@Serializable
data class Envelope(
    val v: Int = Protocol.VERSION,
    val id: String,
    val type: String,
    val replyTo: String? = null,
    val ts: Long,
    val payload: JsonObject = JsonObject(emptyMap()),
)
