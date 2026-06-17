#!/usr/bin/env python3
"""Generate AirNinja conformance test vectors.

Both clients (Android/Kotlin, macOS/Swift) MUST reproduce these exact bytes.
Run: python3 generate_vectors.py  (writes vectors.json next to this file)
See protocol.md for the rules each section encodes.
"""
import base64
import hashlib
import json
import struct
from pathlib import Path


def device_id(static_pub_key: bytes) -> str:
    """base32(SHA-256(static_pub_key)) lowercased, no padding, 52 chars."""
    digest = hashlib.sha256(static_pub_key).digest()
    return base64.b32encode(digest).decode("ascii").rstrip("=").lower()[:52]


def control_frame(payload: bytes) -> bytes:
    """[len:4 BE][type=0x01][payload]  where len = 1 + len(payload)."""
    return struct.pack(">I", 1 + len(payload)) + b"\x01" + payload


def data_frame(stream_id: int, seq: int, final: bool, chunk: bytes) -> bytes:
    """[len:4 BE][type=0x02][streamId:4 BE][seq:8 BE][flags:1][chunk]."""
    sub = struct.pack(">I", stream_id) + struct.pack(">Q", seq) + bytes([1 if final else 0]) + chunk
    return struct.pack(">I", 1 + len(sub)) + b"\x02" + sub


def sas(handshake_hash: bytes) -> str:
    """6-digit SAS = (uint32 BE of first 4 bytes of SHA-256("AIRNINJA-SAS"||hash)) % 1_000_000."""
    digest = hashlib.sha256(b"AIRNINJA-SAS" + handshake_hash).digest()
    return f"{struct.unpack('>I', digest[:4])[0] % 1_000_000:06d}"


def hx(b: bytes) -> str:
    return b.hex()


test_pub_key = bytes(range(32))
envelope = (
    b'{"v":1,"id":"00000000-0000-4000-8000-000000000000",'
    b'"type":"core.ping","ts":0,"payload":{}}'
)
handshake_hash = bytes([0xAA] * 32)

vectors = {
    "version": 1,
    "deviceId": [
        {
            "name": "static-pub-key-0x00..1f",
            "staticPubKeyHex": hx(test_pub_key),
            "deviceId": device_id(test_pub_key),
        }
    ],
    "frameEncoding": [
        {
            "name": "control-core-ping",
            "frameType": "CONTROL",
            "payloadUtf8": envelope.decode("ascii"),
            "frameHex": hx(control_frame(envelope)),
        },
        {
            "name": "data-final-hello",
            "frameType": "DATA",
            "streamId": 1001,
            "seq": 1,
            "final": True,
            "chunkUtf8": "hello",
            "frameHex": hx(data_frame(1001, 1, True, b"hello")),
        },
    ],
    "sasDerivation": [
        {
            "name": "handshake-hash-0xaa..aa",
            "handshakeHashHex": hx(handshake_hash),
            "sas": sas(handshake_hash),
        }
    ],
}

out = Path(__file__).with_name("vectors.json")
out.write_text(json.dumps(vectors, indent=2) + "\n")
print(f"wrote {out}")
