# AirNinja — Documentation

AirNinja is a KDE-Connect-style protocol that links a user's own devices (initially
Android ⇄ macOS) to bridge SMS, share files in both directions, and grow new features over
time.

**Security foundation:** all payloads are **end-to-end encrypted between the two devices on
every transport** — including the cloud relay, which only ever forwards opaque ciphertext
and never holds session keys.

## Documents

- [protocol.md](protocol.md) — the full Phase 1 protocol specification (transport, security
  & pairing, relay design, framing, message envelope, SMS bridge, file transfer,
  extensibility, security considerations, and the message schema reference).

## Phase 1 scope

1. SMS bridge: Android → macOS
2. File share: Android → macOS (AirDrop-like)
3. File share: macOS → Android (AirDrop-like)
4. Universal, capability-negotiated foundation for future features

This phase delivers the **design only** — no application code yet.
