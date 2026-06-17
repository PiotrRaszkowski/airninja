# AirNinja macOS

Native macOS client: a menu-bar app (SwiftUI `MenuBarExtra`) plus a **Share Extension** so
AirNinja appears in the system Share menu for AirDrop-like sending. See
[../docs/tech-stack.md](../docs/tech-stack.md) §4.

## Stack

- **Swift 6 / SwiftUI**, target **macOS 14 (Sonoma)+**
- **CryptoKit** for the Noise suite primitives (X25519, ChaChaPoly, SHA-256, HKDF)
- **Network.framework** + **Bonjour** for transport & discovery
- **UserNotifications**, **Keychain**

## Project generation

The Xcode project is generated from [`project.yml`](project.yml) with **XcodeGen** (the
`.xcodeproj` is not committed). Generate and open it:

```bash
brew install xcodegen      # one-time
cd macos
xcodegen generate
open AirNinja.xcodeproj
```

Targets:
- **AirNinja** — the menu-bar app (`LSUIElement`, no Dock icon).
- **AirNinjaShareExtension** — Share menu entry for sending files to Android.

## SMS receiver (implemented)

The app depends on the local `AirNinjaCore` package and runs as a menu-bar SMS receiver:
- `SmsReceiver` advertises `_airninja._tcp` via `NWListener`/Bonjour, accepts a connection,
  runs the Noise XX handshake as **responder** (`SecureChannel`), then receives
  `sms.message` frames, shows them in the menu bar + posts a `UserNotifications` alert, and
  replies with `core.ack`.
- `ConnectionStream` is a blocking `ByteStream` over `NWConnection` so the synchronous
  `SecureChannel` runs on a worker thread.
- Verified: builds via `xcodebuild`, launches, and advertises `_airninja._tcp` on the LAN.

## Pairing & persistence (implemented)

- **Keychain-persisted identity** (`KeychainIdentityStore`) — stable DeviceId/SAS across launches.
- **Interactive SAS pairing** — an unknown peer triggers an Accept/Reject panel in the menu
  bar showing the 6-digit SAS; on accept the peer's static key is pinned (`TrustStore`).
- **Key pinning / MITM defense** — a known deviceId reconnecting with a *different* static key
  is rejected automatically.
- **Message persistence** (`MessageStore`) — received SMS survive restarts.

Set `AIRNINJA_AUTO_PAIR=1` to auto-accept pairing for headless testing
(see `scripts/macos-e2e-test.sh`).

## Next steps

- Relay fallback (connect out via WebSocket when no LAN peer).
- Full end-to-end verification once the Android sender exists.
- Wire the Share Extension to hand files to the app for transfer.
