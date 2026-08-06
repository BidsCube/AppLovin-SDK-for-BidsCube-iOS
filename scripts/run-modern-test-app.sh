#!/bin/bash
# Build, install, and launch the modern (BidscubeSDKAppLovin) test app on an iOS Simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INTEGRATION="$ROOT/legacyIntegration"
WORKSPACE="$INTEGRATION/LegacySmoke.xcworkspace"
SCHEME="BidscubeSDKAppLovinTestApp"
BUNDLE_ID="com.bidscube.sdktestapp"
DERIVED_DATA="${DERIVED_DATA:-/tmp/modern-test-app-dd}"

SIMULATOR_UDID="${SIMULATOR_UDID:-}"
if [ -z "$SIMULATOR_UDID" ]; then
  SIMULATOR_UDID="$(xcrun simctl list devices available -j \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
preferred = ['iPhone 17', 'iPhone 16', 'iPhone 15']
for name in preferred:
    for runtime, devices in data.get('devices', {}).items():
        if 'iOS' not in runtime:
            continue
        for d in devices:
            if d.get('name') == name and d.get('isAvailable'):
                print(d['udid'])
                raise SystemExit(0)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    for d in devices:
        if d.get('isAvailable') and d.get('name', '').startswith('iPhone'):
            print(d['udid'])
            raise SystemExit(0)
")"
fi

if [ -z "$SIMULATOR_UDID" ]; then
  echo "No available iPhone simulator found."
  exit 1
fi

echo "Using simulator UDID: $SIMULATOR_UDID"

cd "$INTEGRATION"
pod install

xcodebuild build \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=YES \
  -quiet

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/BidscubeSDKAppLovinTestApp.app"
if [ ! -d "$APP_PATH" ]; then
  echo "Built app not found at $APP_PATH"
  exit 1
fi

xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$SIMULATOR_UDID" 2>/dev/null || true
xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"

echo "Modern test app launched on simulator $SIMULATOR_UDID"
echo "Tabs: Banner / Video / Native (direct SDK) + MAX mediation."
