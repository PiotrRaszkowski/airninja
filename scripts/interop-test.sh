#!/usr/bin/env bash
#
# Live Kotlin <-> Swift Noise interop check.
# Starts the Kotlin SecureChannel responder (TCP server) and runs the Swift
# initiator harness against it; asserts both derive the same SAS and the
# encrypted round-trip succeeds.
#
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${1:-38520}"

JAVA_HOME_CANDIDATE="$HOME/.sdkman/candidates/java/21.0.11-zulu"
if [ -d "$JAVA_HOME_CANDIDATE" ]; then
    export JAVA_HOME="$JAVA_HOME_CANDIDATE"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

echo "Building Kotlin responder (installDist)..."
if ! ( cd "$ROOT/protocol-core" && ./gradlew -q installDist ); then
    echo "Kotlin build failed"; exit 1
fi

echo "Building Swift harness..."
if ! ( cd "$ROOT/macos/AirNinjaCore" && swift build -c debug >/dev/null ); then
    echo "Swift build failed"; exit 1
fi

RESP_BIN="$ROOT/protocol-core/build/install/protocol-core/bin/protocol-core"
SWIFT_BIN="$ROOT/macos/AirNinjaCore/.build/debug/InteropHarness"
RESP_OUT="$(mktemp)"

"$RESP_BIN" "$PORT" > "$RESP_OUT" 2>&1 &
RESP_PID=$!
trap 'kill "$RESP_PID" 2>/dev/null || true' EXIT

SWIFT_OUT="$("$SWIFT_BIN" 127.0.0.1 "$PORT")"
SWIFT_EXIT=$?
wait "$RESP_PID" 2>/dev/null || true

echo "--- responder (Kotlin / noise-java) ---"; cat "$RESP_OUT"
echo "--- initiator (Swift / CryptoKit) ---"; echo "$SWIFT_OUT"

RESP_SAS=$(grep -oE 'SAS=[0-9]+' "$RESP_OUT" | head -1 | cut -d= -f2)
SWIFT_SAS=$(echo "$SWIFT_OUT" | grep -oE 'SAS=[0-9]+' | head -1 | cut -d= -f2)

if [ "$SWIFT_EXIT" -eq 0 ] && [ -n "$RESP_SAS" ] && [ "$RESP_SAS" = "$SWIFT_SAS" ] \
    && echo "$SWIFT_OUT" | grep -q 'ACK=ack:hello from swift'; then
    echo "INTEROP PASS (SAS=$RESP_SAS)"
else
    echo "INTEROP FAIL"; exit 1
fi
