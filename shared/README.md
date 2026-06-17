# AirNinja Shared

Cross-platform artifacts that keep the two independent client implementations
(Android/Kotlin and macOS/Swift) byte-compatible. This is the "no shared binary core"
safety net described in [../docs/tech-stack.md](../docs/tech-stack.md) §6.

## Conformance vectors

[`conformance/vectors.json`](conformance/vectors.json) holds fixed inputs and their exact
expected outputs. Both clients run these in CI; any divergence is a conformance failure.

Regenerate (deterministic):

```bash
cd conformance
python3 generate_vectors.py
```

### Sections & rules (see [protocol.md](../docs/protocol.md))

| Section | Rule |
|---------|------|
| `deviceId` | `base32(SHA-256(staticPubKey))`, lowercased, no padding, first 52 chars |
| `frameEncoding` (CONTROL) | `[len:4 BE][0x01][payload]`, `len = 1 + payload` |
| `frameEncoding` (DATA) | `[len:4 BE][0x02][streamId:4 BE][seq:8 BE][flags:1][chunk]`, `flags 0x01 = final` |
| `sasDerivation` | 6-digit `= uint32_BE(SHA-256("AIRNINJA-SAS" ‖ handshakeHash)[:4]) % 1_000_000` |

## Noise handshake vector

[`conformance/noise_xx_vector.json`](conformance/noise_xx_vector.json) is the official
`Noise_XX_25519_ChaChaPoly_SHA256` known-answer vector (from rweather/noise-c,
`tests/vector/noise-c-basic.txt`). The Swift `NoiseVectorTests` reproduces every handshake
and transport message plus the handshake hash byte-for-byte, proving the hand-rolled
CryptoKit implementation matches the spec (and therefore the Kotlin `noise-java` side).

## Next steps

- Optional: JSON Schema files for each message type to validate envelopes.
