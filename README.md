# AirNinja

AirNinja is a KDE-Connect-style companion protocol and app suite that links a user's own
devices — initially **Android ⇄ macOS** — to bridge SMS, share files in both directions
(AirDrop-like), and grow new features over time.

> **Status:** Phase 1 — protocol design. This phase delivers the specification only; no
> application code yet.

## Why

Apple's ecosystem hands you AirDrop and Messages across iPhone and Mac. There is no
equally seamless, **private** bridge between Android and macOS. AirNinja fills that gap with
an open, end-to-end-encrypted protocol you fully control.

## Security foundation

All payloads (SMS, files, every future feature) are **end-to-end encrypted between the two
devices on every transport** — including the optional cloud relay, which only ever forwards
opaque ciphertext and never holds session keys or plaintext.

## Phase 1 features

1. **SMS bridge** — Android → macOS
2. **File share** — Android → macOS (AirDrop-like)
3. **File share** — macOS → Android (AirDrop-like)
4. **Universal foundation** — capability-negotiated, so new features plug in without
   protocol-breaking changes

## Documentation

- **[docs/protocol.md](docs/protocol.md)** — full protocol specification (transport,
  Noise-based security & pairing, relay design, framing, message envelope, SMS bridge, file
  transfer, extensibility, security considerations, message schema reference).
- **[docs/README.md](docs/README.md)** — documentation index.

## Planned repository structure

This will fill in over later phases:

```
airninja/
├── docs/            # protocol specification & design docs   (Phase 1 ✓)
├── android/         # Android client (Kotlin)                (future)
├── macos/           # macOS client (Swift)                   (future)
├── relay/           # optional cloud relay server            (future)
└── shared/          # shared schemas / protocol definitions  (future)
```

## License

[MIT](LICENSE).
