# AirNinjaCore (Swift)

Swift mirror of [`protocol-core`](../../protocol-core) — the transport-agnostic parts of the
AirNinja protocol, built on **CryptoKit**. Consumed by the macOS app as a local Swift
package. See [../../docs/tech-stack.md](../../docs/tech-stack.md) §4.

## What's implemented (Slice 2)

| Area | File |
|------|------|
| Identity keys (Curve25519 / CryptoKit) | `DeviceIdentity.swift` |
| Device ID = base32(SHA-256(pubkey))[:52] | `DeviceId.swift` |
| Frame codec (CONTROL/DATA) | `FrameCodec.swift`, `Frame.swift` |
| SAS derivation (pairing) | `Sas.swift` |
| Base32 / SHA-256 helpers | `Base32.swift`, `Sha256.swift` |

## Test

```bash
swift test
```

`ConformanceVectorsTests` reproduces
[`../../shared/conformance/vectors.json`](../../shared/conformance/vectors.json)
byte-for-byte — the same vectors the Kotlin core passes, guaranteeing the two
implementations agree on the wire.

## Next slices

- Noise XX/IK secure channel over CryptoKit.
- JSON envelope + feature message decoding (`sms.*`).
