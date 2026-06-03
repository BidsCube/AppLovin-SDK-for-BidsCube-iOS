#!/bin/bash
# Sync root BidscubeSDKAppLovin.podspec into the in-repo CocoaPods spec layout.
# Enables: source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
#          pod 'BidscubeSDKAppLovin', '1.0.5'
# No CocoaPods Trunk required.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SRC="BidscubeSDKAppLovin.podspec"
if [ ! -f "$SRC" ]; then
  echo "Missing $SRC"
  exit 1
fi

VERSION=$(grep -m1 'spec\.version' "$SRC" | sed -n 's/.*spec\.version[^"]*"\([^"]*\)".*/\1/p')
if [ -z "$VERSION" ]; then
  echo "Could not parse spec.version from $SRC"
  exit 1
fi
DEST_DIR="BidscubeSDKAppLovin/${VERSION}"
DEST="${DEST_DIR}/BidscubeSDKAppLovin.podspec"

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
echo "Synced $SRC -> $DEST"
