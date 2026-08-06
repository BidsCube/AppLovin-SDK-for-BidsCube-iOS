#!/bin/bash
# Builds a clean legacy CocoaPods integration workspace and verifies dependency graph.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INTEGRATION="$ROOT/legacyIntegration"
WORKSPACE="$INTEGRATION/LegacySmoke.xcworkspace"
SCHEME="LegacySmoke"
POD_TARGET="BidscubeSDKAppLovinLegacy"

cd "$INTEGRATION"
pod install --repo-update

if ! grep -q "AppLovinSDK" Podfile.lock; then
  echo "Legacy integration must depend on AppLovinSDK"
  exit 1
fi

LEGACY_XCCONFIG="$INTEGRATION/Pods/Target Support Files/$POD_TARGET/$POD_TARGET.debug.xcconfig"
if [ ! -f "$LEGACY_XCCONFIG" ]; then
  echo "Missing legacy pod xcconfig at $LEGACY_XCCONFIG"
  exit 1
fi

if grep -q "GoogleAds-IMA" "$LEGACY_XCCONFIG"; then
  echo "Legacy pod must not depend on Google IMA"
  exit 1
fi

if ! grep -q 'IPHONEOS_DEPLOYMENT_TARGET = 14.0' "$INTEGRATION/LegacySmoke.xcodeproj/project.pbxproj"; then
  echo "Legacy integration project must target iOS 14.0"
  exit 1
fi

LEGACY_PODSPEC="$ROOT/BidscubeSDKAppLovinLegacy.podspec"
if ! grep -q 'ios.deployment_target = "14.0"' "$LEGACY_PODSPEC"; then
  echo "Legacy podspec must set ios.deployment_target = 14.0"
  exit 1
fi
if ! grep -q "BIDSCUBE_LEGACY_VIDEO" "$LEGACY_XCCONFIG"; then
  echo "Legacy pod must compile with BIDSCUBE_LEGACY_VIDEO"
  exit 1
fi

xcodebuild build \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -destination 'generic/platform=iOS Simulator' \
  -quiet \
  CODE_SIGNING_ALLOWED=NO

xcodebuild build \
  -workspace "$WORKSPACE" \
  -scheme "BidscubeSDKAppLovinTestApp" \
  -destination 'generic/platform=iOS Simulator' \
  -quiet \
  CODE_SIGNING_ALLOWED=NO

echo "Legacy + modern integration builds succeeded."
