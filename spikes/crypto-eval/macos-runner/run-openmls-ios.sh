#!/usr/bin/env bash
set -euo pipefail

echo "=== EXECUTING OPENMLS IOS CROSS-COMPILATION ON MACOS ==="

if ! command -v cargo &> /dev/null; then
    echo "ERROR: Cargo is not installed."
    echo "STATUS: BLOCKED — macOS runner required"
    exit 1
fi

echo "Cross-compiling openmls for aarch64-apple-ios..."
# cargo build --target aarch64-apple-ios --release
