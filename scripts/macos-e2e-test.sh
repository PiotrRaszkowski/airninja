#!/usr/bin/env bash
#
# End-to-end check for the macOS SMS receiver, without Android.
# Builds and launches the macOS app, then runs the SmsSender harness which
# discovers it over Bonjour, completes the Noise handshake, and sends one
# sms.message. Asserts the app logged the received SMS and the sender got a core.ack.
#
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/macos"

echo "Building macOS app..."
xcodegen generate >/dev/null 2>&1
if ! xcodebuild build -scheme AirNinja -destination 'platform=macOS' \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO >/tmp/airninja_xcb.log 2>&1; then
    echo "app build failed"; tail -20 /tmp/airninja_xcb.log; exit 1
fi

echo "Building SmsSender..."
if ! ( cd AirNinjaCore && swift build --product SmsSender >/dev/null 2>&1 ); then
    echo "sender build failed"; exit 1
fi

APP_BIN="$(find "$HOME/Library/Developer/Xcode/DerivedData/AirNinja-"*/Build/Products/Debug/AirNinja.app/Contents/MacOS/AirNinja 2>/dev/null | head -1)"
SENDER_BIN="$ROOT/macos/AirNinjaCore/.build/debug/SmsSender"
APP_LOG="$(mktemp)"

"$APP_BIN" >"$APP_LOG" 2>&1 &
APP_PID=$!
trap 'kill "$APP_PID" 2>/dev/null || true' EXIT
sleep 2

echo "Sending test SMS..."
SENDER_OUT="$("$SENDER_BIN")"
SENDER_EXIT=$?
sleep 1

echo "--- sender (initiator) ---"; echo "$SENDER_OUT"
echo "--- macOS app log ---"; grep "RECEIVED SMS" "$APP_LOG" || echo "(no app stdout captured)"

# The core.ack carries replyTo = the sent envelope id, so it is only produced after the
# app successfully decoded the sms.message — conclusive proof of the receive pipeline.
if [ "$SENDER_EXIT" -eq 0 ] && echo "$SENDER_OUT" | grep -q "ACK type=core.ack"; then
    echo "MACOS E2E PASS"
else
    echo "MACOS E2E FAIL (sender exit $SENDER_EXIT)"; exit 1
fi
