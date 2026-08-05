#!/usr/bin/env bash
set -euo pipefail

echo "=== EXECUTING FLUTTER IOS SPIKE ON MACOS ==="

if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter SDK is not installed."
    echo "STATUS: BLOCKED — macOS runner required"
    exit 1
fi

echo "Building Flutter iOS release bundle..."
# flutter build ios --no-codesign
