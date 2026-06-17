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

## Next steps (implementation phase)

- Noise handshake layer over CryptoKit + framing/transfer state machines.
- Bonjour discovery (`_airninja._tcp`) and `NWConnection` transport.
- Pairing UI (SAS / QR), Keychain-backed identity key.
- Wire the Share Extension to hand files to the app for transfer.
