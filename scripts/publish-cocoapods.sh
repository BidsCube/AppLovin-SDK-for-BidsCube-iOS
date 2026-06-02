#!/bin/bash
# Publish BidscubeSDKAppLovin to CocoaPods Trunk.
# Requires: pod trunk register (once) and pod trunk me (valid session).
# GitHub Actions alternative: push tag v* with secret COCOAPODS_TRUNK_TOKEN set.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SPEC="BidscubeSDKAppLovin.podspec"

if ! pod trunk me >/dev/null 2>&1; then
  echo "Not logged in to CocoaPods Trunk."
  echo "Run: pod trunk register YOUR_EMAIL --description='Bidscube SDK machine'"
  exit 1
fi

echo "Linting $SPEC..."
pod lib lint "$SPEC" --allow-warnings

echo "Publishing $SPEC to CocoaPods Trunk..."
pod trunk push "$SPEC" --allow-warnings

echo "Done. After indexing (~10 min), integrators can use:"
echo "  pod 'BidscubeSDKAppLovin', '$(grep spec.version "$SPEC" | sed 's/.*"\(.*\)".*/\1/')'"
