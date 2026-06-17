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

## macos-e2e-test.sh

End-to-end check of the **macOS SMS receiver** without an Android device. Builds and launches
the macOS app, then runs the `SmsSender` harness which discovers it over Bonjour, completes
the Noise handshake, and sends one `sms.message`. Asserts the app received and decoded it
(it logs `RECEIVED SMS …` and replies with a `core.ack` referencing the sent envelope).

```bash
./scripts/macos-e2e-test.sh
```

Sender source: `macos/AirNinjaCore/Sources/SmsSender/main.swift`.
