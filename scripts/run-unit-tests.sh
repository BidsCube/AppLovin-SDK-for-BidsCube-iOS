#!/bin/bash
# Run bidscubeSdkTests on an available iOS Simulator via Swift Package Manager.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_PACKAGE="$ROOT/spmUnitTests"
cd "$TEST_PACKAGE"

swift package resolve

SIMULATOR_UDID="$(
  xcrun simctl list devices available -j \
    | python3 -c '
import json, sys
data = json.load(sys.stdin)
devices = []
for runtime, entries in data.get("devices", {}).items():
    if "iOS" not in runtime:
        continue
    for device in entries:
        if not device.get("isAvailable", False):
            continue
        if "iPhone" not in device.get("name", ""):
            continue
        devices.append(device)
devices.sort(key=lambda d: d.get("name", ""))
if not devices:
    sys.exit(1)
print(devices[0]["udid"])
'
)"

if [ -z "${SIMULATOR_UDID:-}" ]; then
  echo "No available iPhone Simulator found."
  exit 1
fi

echo "Running unit tests on simulator id=$SIMULATOR_UDID"

xcodebuild test \
  -scheme BidscubeSDKUnitTests-Package \
  -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
  -derivedDataPath /tmp/bidscube-unit-test-dd \
  -parallel-testing-enabled NO \
  -quiet \
  CODE_SIGNING_ALLOWED=NO
