package com.airninja.protocol.framing

import java.nio.ByteBuffer

object FrameCodec {
    const val TYPE_CONTROL = 0x01
    const val TYPE_DATA = 0x02
    const val MAX_FRAME_LENGTH = 1 shl 20

    private const val LENGTH_FIELD = 4
    private const val TYPE_FIELD = 1
    private const val STREAM_ID_FIELD = 4
    private const val SEQUENCE_FIELD = 8
    private const val FLAGS_FIELD = 1
    private const val FLAG_FINAL = 0x01

    fun encode(frame: Frame): ByteArray =
        when (frame) {
            is Frame.Control -> encodeBody(TYPE_CONTROL, frame.payload)
            is Frame.Data -> encodeBody(TYPE_DATA, encodeDataSubHeader(frame))
        }

    fun decode(frame: ByteArray): Frame {
        require(frame.size >= LENGTH_FIELD + TYPE_FIELD) { "Frame too short" }
        val buffer = ByteBuffer.wrap(frame)
        val declaredLength = buffer.int
        require(declaredLength == frame.size - LENGTH_FIELD) { "Frame length mismatch" }
        require(declaredLength <= MAX_FRAME_LENGTH) { "Frame exceeds maximum length" }
        return when (val type = buffer.get().toInt() and 0xFF) {
            TYPE_CONTROL -> decodeControl(buffer)
            TYPE_DATA -> decodeData(buffer)
            else -> throw IllegalArgumentException("Unknown frame type: $type")
        }
    }

    private fun encodeBody(type: Int, body: ByteArray): ByteArray {
        val length = TYPE_FIELD + body.size
        require(length <= MAX_FRAME_LENGTH) { "Frame exceeds maximum length" }
        return ByteBuffer.allocate(LENGTH_FIELD + length)
            .putInt(length)
            .put(type.toByte())
            .put(body)
            .array()
    }

    private fun encodeDataSubHeader(frame: Frame.Data): ByteArray {
        val flags = if (frame.isFinal) FLAG_FINAL else 0
        return ByteBuffer.allocate(STREAM_ID_FIELD + SEQUENCE_FIELD + FLAGS_FIELD + frame.chunk.size)
            .putInt(frame.streamId)
            .putLong(frame.sequence)
            .put(flags.toByte())
            .put(frame.chunk)
            .array()
    }

    private fun decodeControl(buffer: ByteBuffer): Frame.Control {
        val payload = ByteArray(buffer.remaining())
        buffer.get(payload)
        return Frame.Control(payload)
    }

    private fun decodeData(buffer: ByteBuffer): Frame.Data {
        require(buffer.remaining() >= STREAM_ID_FIELD + SEQUENCE_FIELD + FLAGS_FIELD) {
            "Data frame sub-header truncated"
        }
        val streamId = buffer.int
        val sequence = buffer.long
        val isFinal = (buffer.get().toInt() and FLAG_FINAL) == FLAG_FINAL
        val chunk = ByteArray(buffer.remaining())
        buffer.get(chunk)
        return Frame.Data(streamId, sequence, isFinal, chunk)
    }
}
