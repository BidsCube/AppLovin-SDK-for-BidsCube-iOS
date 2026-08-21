#!/bin/bash
# Run bidscubeSdkTests on an available iOS Simulator via Swift Package Manager.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_PACKAGE="$ROOT/spmUnitTests"
ARTIFACTS="$ROOT/artifacts"
ARTIFACT_LOG="$ARTIFACTS/unit-tests.log"
PARENT_FULL_RUN="${PARENT_FULL_RUN:-0}"
# shellcheck source=artifact-header.sh
source "$ROOT/scripts/artifact-header.sh"

mkdir -p "$ARTIFACTS"
export RUN_ID="${RUN_ID:-$(date -u +"%Y%m%dT%H%M%SZ")-$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo nogit)}"

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

ARTIFACT_SCHEME="BidscubeSDKUnitTests-Package"
CMD="xcodebuild test -scheme BidscubeSDKUnitTests-Package -destination platform=iOS Simulator,id=${SIMULATOR_UDID}"

{
  artifact_header "unit-tests" "$CMD"
  echo "Running unit tests on simulator id=$SIMULATOR_UDID"
  xcodebuild test \
    -scheme BidscubeSDKUnitTests-Package \
    -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
    -derivedDataPath "/tmp/bidscube-unit-test-dd-${RUN_ID}" \
    -parallel-testing-enabled NO \
    CODE_SIGNING_ALLOWED=NO
} > "$ARTIFACT_LOG" 2>&1

UNIT_EXIT=$?
if [ "$PARENT_FULL_RUN" != "1" ]; then
  {
    echo "run_id=$RUN_ID"
    echo "unit_exit_code=$UNIT_EXIT"
  } > "$ARTIFACTS/test-summary.txt"
fi
exit "$UNIT_EXIT"
