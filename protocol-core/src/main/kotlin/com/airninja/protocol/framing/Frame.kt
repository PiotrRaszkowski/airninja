package com.airninja.protocol.framing

sealed interface Frame {
    class Control(payload: ByteArray) : Frame {
        val payload: ByteArray = payload.copyOf()
            get() = field.copyOf()
    }

    class Data(
        val streamId: Int,
        val sequence: Long,
        val isFinal: Boolean,
        chunk: ByteArray,
    ) : Frame {
        val chunk: ByteArray = chunk.copyOf()
            get() = field.copyOf()
    }
}
