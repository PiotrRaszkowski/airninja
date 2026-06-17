# AirNinja Relay

Stateless WebSocket relay that forwards **opaque ciphertext** between AirNinja devices that
cannot reach each other on a LAN. It never holds session keys or plaintext — see
[../docs/protocol.md](../docs/protocol.md) §7.

## Stack

- **Java 21 (Zulu, LTS)** with virtual threads (Project Loom) for scalable blocking I/O
- **Spring Boot 4.1** — `webmvc`, `websocket`, `actuator`
- **Gradle** via the project wrapper (`./gradlew`)

## Toolchain

Java is pinned in [`.sdkmanrc`](.sdkmanrc). Activate it before building:

```bash
sdk env        # selects java 21.0.11-zulu
./gradlew build
./gradlew bootRun
```

Health check once running: `http://localhost:8080/actuator/health`.

## Responsibilities (per protocol §7)

- Identity-authenticated registration (`deviceId`) — routing only, not a trust anchor.
- Route encrypted frames by destination `deviceId`.
- Presence notifications to paired peers.
- Short-lived **store-and-forward** of ciphertext for offline peers.

## Next steps (implementation phase)

- WebSocket endpoint + frame router (`deviceId → session`).
- Challenge–response registration over the device identity key.
- Pluggable routing store (in-memory → Redis pub/sub) for horizontal scale.
