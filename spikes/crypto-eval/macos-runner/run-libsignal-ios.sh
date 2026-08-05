#!/usr/bin/env bash
set -euo pipefail

echo "=== EXECUTING LIBSIGNAL IOS SPIKE ON MACOS ==="

if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: xcodebuild is not installed or not in PATH."
    echo "STATUS: BLOCKED — macOS runner required"
    exit 1
fi

echo "Building libsignal iOS spike..."
# xcodebuild -workspace LibSignalSpike.xcworkspace -scheme LibSignalSpike -sdk iphonesimulator build
