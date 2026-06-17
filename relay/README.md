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

## WebSocket protocol (endpoint `/relay`)

JSON text messages. The relay sees only opaque `payload` ciphertext — never plaintext or keys.

Client → relay:
- `{"type":"register","deviceId":"<id>"}` — claim a deviceId for this connection.
- `{"type":"send","to":"<id>","payload":"<ciphertext>"}` — route ciphertext to a peer.

Relay → client:
- `{"type":"registered","detail":"<id>"}` — registration ack.
- `{"type":"deliver","from":"<id>","payload":"<ciphertext>"}` — a routed frame.
- `{"type":"error","detail":"<message>"}`.

Behaviour: route by destination `deviceId` to the online connection; if the peer is offline,
**store-and-forward** (bounded queue, flushed on its next `register`).

Implemented in `core/RelayService` (logic, unit-tested) + `ws/RelayWebSocketHandler`
(transport) + `core/ConnectionRegistry` / `core/PendingMessageStore`. Verified by
`RelayServiceTest` (Mockito) and `RelayWebSocketIntegrationTest` (live two-client routing).

## Next steps

- Challenge–response registration over the device identity key (routing-auth hardening;
  the relay is not a trust anchor — E2E Noise + SAS pinning is the real security).
- Presence notifications to paired peers.
- Pluggable routing store (in-memory → Redis pub/sub) for horizontal scale.
- Client-side relay fallback wiring (when LAN discovery fails) — done with the apps.
