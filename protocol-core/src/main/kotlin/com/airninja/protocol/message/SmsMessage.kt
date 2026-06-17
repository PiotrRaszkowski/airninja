package com.airninja.protocol.message

import kotlinx.serialization.Serializable

@Serializable
data class SmsMessage(
    val sender: String,
    val body: String,
    val timestamp: Long,
    val messageId: String,
)
