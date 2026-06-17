package com.airninja.protocol.transport

import java.io.EOFException
import java.io.InputStream
import java.io.OutputStream

object StreamFraming {
    const val MAX_FRAME_LENGTH = 0xFFFF

    fun writeFrame(output: OutputStream, payload: ByteArray) {
        require(payload.size <= MAX_FRAME_LENGTH) { "Frame exceeds $MAX_FRAME_LENGTH bytes" }
        output.write((payload.size ushr 8) and 0xFF)
        output.write(payload.size and 0xFF)
        output.write(payload)
        output.flush()
    }

    fun readFrame(input: InputStream): ByteArray {
        val length = (readByte(input) shl 8) or readByte(input)
        val payload = ByteArray(length)
        var offset = 0
        while (offset < length) {
            val read = input.read(payload, offset, length - offset)
            if (read < 0) throw EOFException("Stream closed mid-frame")
            offset += read
        }
        return payload
    }

    private fun readByte(input: InputStream): Int {
        val value = input.read()
        if (value < 0) throw EOFException("Stream closed")
        return value
    }
}
