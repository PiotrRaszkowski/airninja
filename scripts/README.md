# scripts

## interop-test.sh

Live cross-language Noise interop check. Builds the Kotlin `SecureChannel` responder
(`protocol-core`, noise-java) and the Swift initiator harness (`macos/AirNinjaCore`,
hand-rolled CryptoKit), connects them over a real TCP socket, and asserts:

- both ends derive the **same SAS** (identical handshake hash → mutual authentication),
- the encrypted application frame round-trips (`hello from swift` → `ack:hello from swift`).

```bash
./scripts/interop-test.sh [port]   # default port 38520
```

This is the end-to-end proof that the two independent Noise implementations interoperate.
The harness sources are `protocol-core` `com.airninja.protocol.interop.InteropResponder` and
`macos/AirNinjaCore/Sources/InteropHarness/main.swift`.
