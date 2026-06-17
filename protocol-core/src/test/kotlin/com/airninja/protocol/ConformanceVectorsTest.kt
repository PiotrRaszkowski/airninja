package com.airninja.protocol

import com.airninja.protocol.framing.Frame
import com.airninja.protocol.framing.FrameCodec
import com.airninja.protocol.identity.DeviceId
import com.airninja.protocol.pairing.Sas
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import java.io.File

class ConformanceVectorsTest {

    private val vectors = Json.parseToJsonElement(loadVectors()).jsonObject

    @Test
    fun deviceIdVectorsMatch() {
        //GIVEN
        val cases = vectors["deviceId"]!!.jsonArray

        //WHEN / THEN
        cases.forEach { case ->
            val obj = case.jsonObject
            val publicKey = Hex.decode(obj["staticPubKeyHex"]!!.jsonPrimitive.content)
            assertThat(DeviceId.fromPublicKey(publicKey))
                .isEqualTo(obj["deviceId"]!!.jsonPrimitive.content)
        }
    }

    @Test
    fun frameEncodingVectorsMatch() {
        //GIVEN
        val cases = vectors["frameEncoding"]!!.jsonArray

        //WHEN / THEN
        cases.forEach { case ->
            val obj = case.jsonObject
            val frame = when (val type = obj["frameType"]!!.jsonPrimitive.content) {
                "CONTROL" -> Frame.Control(obj["payloadUtf8"]!!.jsonPrimitive.content.toByteArray(Charsets.UTF_8))
                "DATA" -> Frame.Data(
                    streamId = obj["streamId"]!!.jsonPrimitive.int,
                    sequence = obj["seq"]!!.jsonPrimitive.long,
                    isFinal = obj["final"]!!.jsonPrimitive.boolean,
                    chunk = obj["chunkUtf8"]!!.jsonPrimitive.content.toByteArray(Charsets.UTF_8),
                )
                else -> throw IllegalArgumentException("Unknown frame type: $type")
            }
            assertThat(Hex.encode(FrameCodec.encode(frame)))
                .isEqualTo(obj["frameHex"]!!.jsonPrimitive.content)
        }
    }

    @Test
    fun sasDerivationVectorsMatch() {
        //GIVEN
        val cases = vectors["sasDerivation"]!!.jsonArray

        //WHEN / THEN
        cases.forEach { case ->
            val obj = case.jsonObject
            val handshakeHash = Hex.decode(obj["handshakeHashHex"]!!.jsonPrimitive.content)
            assertThat(Sas.derive(handshakeHash)).isEqualTo(obj["sas"]!!.jsonPrimitive.content)
        }
    }

    private fun loadVectors(): String {
        val candidates = listOf(
            File("../shared/conformance/vectors.json"),
            File("shared/conformance/vectors.json"),
        )
        val file = candidates.firstOrNull { it.exists() }
            ?: throw IllegalStateException("Conformance vectors not found in ${candidates.map { it.absolutePath }}")
        return file.readText()
    }
}
