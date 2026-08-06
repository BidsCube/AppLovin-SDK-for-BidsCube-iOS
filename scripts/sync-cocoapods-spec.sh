#!/bin/bash
# Sync root podspecs into the in-repo CocoaPods spec layout.
# Enables:
#   source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
#   pod 'BidscubeSDKAppLovin', '1.1.3'
#   pod 'BidscubeSDKAppLovinLegacy', '1.1.3'
# No CocoaPods Trunk required.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

sync_podspec() {
  local src="$1"
  local pod_name="$2"

  if [ ! -f "$src" ]; then
    echo "Missing $src"
    exit 1
  fi

  local version
  version=$(grep -m1 'spec\.version' "$src" | sed -n 's/.*spec\.version[^"]*"\([^"]*\)".*/\1/p')
  if [ -z "$version" ]; then
    echo "Could not parse spec.version from $src"
    exit 1
  fi

  local dest_dir="${pod_name}/${version}"
  local dest="${dest_dir}/${pod_name}.podspec"
  mkdir -p "$dest_dir"
  cp "$src" "$dest"
  echo "Synced $src -> $dest"
}

sync_podspec "BidscubeSDKAppLovin.podspec" "BidscubeSDKAppLovin"
sync_podspec "BidscubeSDKAppLovinLegacy.podspec" "BidscubeSDKAppLovinLegacy"
