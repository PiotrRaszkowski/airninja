# AirNinja — Technology Stack

**Status:** Phase 1 — stack design. Companion to [protocol.md](protocol.md).

This document picks the technologies for each AirNinja component and explains *why*. It is
deliberately Rust-free and leans on the JVM where it helps, matching the team's expertise.

---

## 1. Guiding principles

- **No hand-rolled cryptography.** Every component uses a mature, audited library for the
  Noise suite primitives (X25519, ChaCha20-Poly1305, SHA-256, HKDF).
- **Best-in-class native integration over maximum code reuse.** AirDrop-like UX needs deep
  OS hooks (Share Extension, menu bar, notifications), so the macOS client is native.
- **A precise spec is the contract, not a shared binary.** The two clients implement the
  same wire protocol independently and are kept honest by shared conformance test vectors.
- **Play to JVM strengths.** Android's protocol core and the relay are JVM, where the team
  is strongest; the security-critical handshake reuses the well-known `noise-java` library.

---

## 2. High-level picture

```
        ┌───────────────────────────┐         ┌───────────────────────────┐
        │        ANDROID            │         │          macOS            │
        │  Flutter (Dart) — UI      │         │  SwiftUI — UI             │
        │  ── platform channels ──  │         │  ──────────────────────   │
        │  Kotlin core:             │         │  Swift core:              │
        │   • noise-java handshake  │         │   • CryptoKit + Noise     │
        │   • framing / transfers   │         │   • framing / transfers   │
        │   • TCP / mDNS / WS       │         │   • Network.framework     │
        │   • SMS / background svc  │         │   • Bonjour / Keychain    │
        └─────────────┬─────────────┘         └─────────────┬─────────────┘
                      │            E2E Noise session (ciphertext only)      │
                      │  ┌──────────────────────────────────────────────┐  │
                      └──┤   RELAY  (Java 25 + Spring Boot, Loom vthreads)├──┘
                         │   WebSocket ciphertext router, presence,       │
                         │   store-and-forward — never sees plaintext     │
                         └──────────────────────────────────────────────┘
                                  (LAN path bypasses the relay entirely)
```

---

## 3. Android client

| Concern | Choice |
|---------|--------|
| UI | **Flutter (Dart)** — single, fast UI toolkit (per requirement) |
| Protocol & crypto core | **Kotlin module** using **`noise-java`** (`com.southernstorm.noise`) |
| Dart ↔ native bridge | **Platform channels** (`MethodChannel` + `EventChannel`) |
| Networking | Kotlin: Java NIO / OkHttp (WebSocket to relay) |
| Discovery | Android **NSD** (`NsdManager`) for mDNS, UDP `DatagramSocket` fallback |
| SMS access | Native `SmsManager`, `Telephony` content observer, `BroadcastReceiver` (`RECEIVE_SMS`/`READ_SMS`) |
| Background execution | **Foreground Service** + `WorkManager` for reconnect/sync |
| Key storage | **Android Keystore** (hardware-backed where available) |
| Local DB | **Room / SQLite** (SMS cache, transfer state, paired peers) |

**Why Flutter for UI but Kotlin for the core?** Flutter gives the UI experience you want,
while the connectivity, SMS, background service and Noise handshake must be native on Android
anyway. Putting the entire protocol core in Kotlin (a) keeps security-critical code in one
JVM place using the proven `noise-java`, and (b) plays to your JVM strengths. Flutter is the
UI shell + orchestration; Kotlin does the heavy lifting and emits events over channels.

`noise-java` implements exactly our suite — `Noise_XX`/`Noise_IK`, `25519`, `ChaChaPoly`,
`SHA256` — so we don't implement the handshake ourselves.

---

## 4. macOS client

| Concern | Choice |
|---------|--------|
| UI | **SwiftUI** with **`MenuBarExtra`** (lives in the menu bar, like AirDrop helpers) |
| Protocol & crypto core | **Swift** using **CryptoKit** (`Curve25519.KeyAgreement`, `ChaChaPoly`, `SHA256`, `HKDF`) + a thin Noise handshake layer over those primitives |
| Networking | **Network.framework** (`NWConnection`/`NWListener`) for TCP; `URLSessionWebSocketTask` for the relay |
| Discovery | **Bonjour** via `NWBrowser` / `NWListener` advertising `_airninja._tcp` |
| Send files from system | **Share Extension** (App Extension) — AirNinja appears in the macOS Share menu |
| Notifications | **UserNotifications** framework (incoming SMS, transfer prompts) |
| Key storage | **Keychain** (Secure Enclave-backed where available) |
| Local store | **SQLite** (GRDB) or Core Data for caches/state |
| Packaging | **Xcode** project, **Swift Package Manager** for deps, signed `.app` + Share Extension |

**Why native Swift?** The AirDrop-like feel depends on a Share Extension, a menu-bar app,
native notifications and Keychain — all of which are first-party Apple APIs. CryptoKit gives
us audited X25519/ChaChaPoly/SHA-256, so the only bespoke piece is wiring those primitives
into the Noise state machine, guided by the spec and verified against shared test vectors.

---

## 5. Relay server

A stateless service that forwards opaque ciphertext between devices that can't reach each
other on a LAN. It never holds session keys or plaintext (see protocol §7).

| Concern | Choice |
|---------|--------|
| Language / runtime | **Java 25 (LTS, Zulu via sdkman)** |
| Framework | **Spring Boot 3.x** |
| Transport | **WebSocket** (`spring-boot-starter-websocket`), WSS via TLS termination |
| Concurrency | **Virtual threads (Project Loom)** — `spring.threads.virtual.enabled=true` |
| Build | **Gradle (Kotlin DSL)** or Maven; pinned via `.sdkmanrc` |
| Routing state | In-memory `deviceId → session` map; pluggable store later |
| Store-and-forward | Short-lived queue of **ciphertext** frames for offline peers |
| Auth (routing only) | Challenge–response signature over the device identity key |
| Observability | Spring Actuator + Micrometer |
| Deploy | Container (Docker) to Fly.io / Railway / any VPS; horizontally scalable behind sticky LB |

**Why Java + Spring + Loom?** A relay is mostly idle, blocking I/O across many long-lived
connections — historically awkward for thread-per-connection servlets. Virtual threads make
the familiar blocking Spring style scale to tens of thousands of connections without
reactive complexity. And because the relay only shuffles ciphertext, it carries **zero**
cryptographic responsibility beyond TLS, which Spring handles for us. This is squarely in
your wheelhouse.

> If the connection count ever outgrows a single node, the in-memory routing map moves to a
> shared pub/sub (e.g. Redis), and nodes forward frames to whichever node holds the
> destination connection — no protocol change required.

---

## 6. Shared protocol core strategy (the Rust alternative)

We **do not** ship a shared binary core. Instead:

1. **The spec ([protocol.md](protocol.md)) is the single source of truth.**
2. **Each platform uses a mature Noise/crypto library** so nothing security-critical is
   hand-written:

   | Primitive | Android (Kotlin) | macOS (Swift) |
   |-----------|------------------|---------------|
   | Noise framework | `noise-java` | thin layer over CryptoKit (or a Swift Noise lib) |
   | X25519 ECDH | `noise-java` / Bouncy Castle | `CryptoKit.Curve25519` |
   | ChaCha20-Poly1305 | `noise-java` / JCA | `CryptoKit.ChaChaPoly` |
   | SHA-256 / HKDF | `noise-java` / JCA | `CryptoKit.SHA256` / `HKDF` |
   | JSON envelope | `kotlinx.serialization` | `Codable` |

3. **Conformance test vectors in `shared/`** keep the two implementations byte-identical:
   fixed handshake inputs → expected handshake outputs, frame encodings, SAS derivation, and
   sample message envelopes. Both clients run these vectors in CI. This replaces the
   "shared binary" safety net without FFI and without Rust.

### Alternative considered: Kotlin Multiplatform (KMP)
A true single shared core in Kotlin (Android `.aar` + Apple framework) is possible and
JVM-friendly, but bridging KMP into a **Flutter** UI still needs an FFI/channel layer on
Android, and the Swift side consumes a generated framework rather than idiomatic Swift. The
two-native-cores + conformance-vectors approach is simpler to start and avoids coupling the
clients. KMP remains an option if code duplication becomes painful later.

---

## 7. Cross-cutting

- **Serialization:** JSON control envelopes (`kotlinx.serialization` / `Codable` / Jackson
  on the relay). Binary `DATA` frames are raw bytes per protocol §8.
- **Versioning of tools:** `.sdkmanrc` pins **Java** (`25.x-zulu`) and **Gradle** for the
  relay and any Android Gradle usage, per project convention. Run `sdk env` before builds.
- **CI:** GitHub Actions matrix — build/test Android (Flutter + Kotlin unit tests), macOS
  (Xcode build + Swift tests), relay (Gradle/Spring tests), and a **conformance job** that
  runs the shared vectors against both clients.
- **Testing:** JUnit5 + Mockito + AssertJ on JVM (relay, Kotlin core), `XCTest`/Swift
  Testing on macOS, `flutter_test` for Dart UI.

---

## 8. Repository layout (monorepo)

```
airninja/
├── docs/            # protocol.md, tech-stack.md, design docs       (Phase 1 ✓)
├── android/         # Flutter app + android/ Kotlin protocol core    (future)
├── macos/           # Swift/SwiftUI app + Share Extension            (future)
├── relay/           # Java 25 + Spring Boot WebSocket relay          (future)
└── shared/          # conformance test vectors + JSON schemas        (future)
```

---

## 9. Version targets (pin exact values in `.sdkmanrc` / lockfiles)

| Component | Target |
|-----------|--------|
| Flutter / Dart | Flutter stable 3.x / Dart 3.x |
| Android | Kotlin 2.x, AGP 8.x, minSdk 26+, NSD/Telephony APIs |
| macOS | Swift 6, SwiftUI, target macOS 14 (Sonoma)+ |
| Relay | Java 25-zulu (sdkman), Spring Boot 3.x, Gradle 8.x |
| Noise (Android) | `noise-java` latest |
| Crypto (macOS) | CryptoKit (OS-provided) |

---

## 10. Decision summary

| Area | Decision | Key reason |
|------|----------|------------|
| Android UI | Flutter (Dart) | Requested; good UI velocity |
| Android core | Kotlin + `noise-java` via platform channels | Native APIs required anyway; proven Noise lib; JVM strength |
| macOS | Native Swift + SwiftUI + CryptoKit | Real AirDrop-like integration (Share Extension, menu bar, Keychain) |
| Shared core | Two native cores + conformance vectors (no Rust, no FFI) | No hand-rolled crypto; simple toolchain; spec is the contract |
| Relay | Java 25 + Spring Boot + Loom | Familiar JVM; vthreads scale blocking I/O; relay carries no crypto |
