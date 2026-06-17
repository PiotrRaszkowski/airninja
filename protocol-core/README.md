# AirNinja protocol-core (Kotlin/JVM)

Pure-JVM Kotlin library implementing the transport-agnostic parts of the AirNinja protocol.
No Android dependencies, so it is fast to unit-test (F.I.R.S.T.) and is consumed by the
Android app as a plain library (wired to Flutter via platform channels). See
[../docs/tech-stack.md](../docs/tech-stack.md) §3.

## What's implemented (Slice 1)

| Area | Type |
|------|------|
| Identity keys (X25519, BouncyCastle) | `identity/DeviceIdentity` |
| Device ID = base32(SHA-256(pubkey))[:52] | `identity/DeviceId` |
| Frame codec (CONTROL/DATA, length-prefixed) | `framing/FrameCodec`, `framing/Frame` |
| JSON envelope (kotlinx.serialization) | `message/Envelope`, `message/EnvelopeCodec` |
| SAS derivation (pairing) | `pairing/Sas` |

## Build & test

```bash
sdk env          # java 21.0.11-zulu
./gradlew test
```

Tests include `ConformanceVectorsTest`, which asserts this implementation reproduces
[`../shared/conformance/vectors.json`](../shared/conformance/vectors.json) byte-for-byte —
the same vectors the Swift core must pass.

## Next slices

- Noise XX/IK secure channel (via `noise-java`).
- Feature message builders (`sms.*`, `files.*`).
