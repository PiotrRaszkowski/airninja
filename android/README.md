# AirNinja Android

Android client: a **Flutter (Dart)** UI on top of a native **Kotlin** protocol core. See
[../docs/tech-stack.md](../docs/tech-stack.md) §3.

## Stack

- **Flutter / Dart** — UI shell and orchestration
- **Kotlin** (under `android/`) — protocol & crypto core via **`noise-java`**, exposed to
  Dart through **platform channels**
- **NSD** (mDNS) + UDP fallback, **OkHttp** WebSocket to the relay
- **Telephony** APIs for SMS, **Foreground Service** + **WorkManager** for background sync
- **Android Keystore** for the identity key, **Room** for local cache

## Run

```bash
flutter pub get
flutter run        # on a connected Android device/emulator
```

## Next steps (implementation phase)

- Kotlin protocol core module (`noise-java` handshake, framing, transfer state machines).
- Platform channels: `MethodChannel` (commands) + `EventChannel` (incoming events).
- SMS reader/observer + foreground connection service.
- Pairing UI (SAS / QR) and the file share sheet integration.
