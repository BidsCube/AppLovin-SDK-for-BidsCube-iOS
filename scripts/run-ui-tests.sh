#!/bin/bash
# XCUITest real-touch input verification for Legacy and Modern test apps.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACTS="$ROOT/artifacts"
INTEGRATION="$ROOT/legacyIntegration"
WORKSPACE="$INTEGRATION/LegacySmoke.xcworkspace"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
UI_TEST_MODE="${UI_TEST_MODE:-all}"
PARENT_FULL_RUN="${PARENT_FULL_RUN:-0}"
ALLOW_LEGACY_SMOKE_LOG="${ALLOW_LEGACY_SMOKE_LOG:-0}"
# shellcheck source=artifact-header.sh
source "$ROOT/scripts/artifact-header.sh"

mkdir -p "$ARTIFACTS"

if [ -z "$SIMULATOR_UDID" ]; then
  SIMULATOR_UDID="$(xcrun simctl list devices available -j \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
for name in ['iPhone 17', 'iPhone 16', 'iPhone 15']:
    for runtime, devices in data.get('devices', {}).items():
        if 'iOS' not in runtime:
            continue
        for d in devices:
            if d.get('name') == name and d.get('isAvailable'):
                print(d['udid'])
                raise SystemExit(0)
")"
fi

if [ -z "$SIMULATOR_UDID" ]; then
  echo "[SmokeInfo] FAIL ui_tests no_simulator"
  exit 1
fi

export RUN_ID="${RUN_ID:-$(date -u +"%Y%m%dT%H%M%SZ")-$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo nogit)}"
export BIDSCUBE_EXPECTED_RUN_ID="$RUN_ID"
export BIDSCUBE_EXPECTED_SCHEMA="2"
XCODE_BUILD_FLAGS=(ONLY_ACTIVE_ARCH=YES EXCLUDED_ARCHS=x86_64 CODE_SIGNING_ALLOWED=YES)
export DERIVED_UI="${DERIVED_UI:-/tmp/bidscube-${RUN_ID}-ui-dd}"
rm -rf "$DERIVED_UI"

ACTIVE_RUNTIME_PID=""
ACTIVE_RUNTIME_LOG=""
ACTIVE_TEST_BUNDLE=""

cleanup_ui_runner() {
  if [ -n "$ACTIVE_RUNTIME_PID" ] && kill -0 "$ACTIVE_RUNTIME_PID" 2>/dev/null; then
    kill "$ACTIVE_RUNTIME_PID" 2>/dev/null || true
    wait "$ACTIVE_RUNTIME_PID" 2>/dev/null || true
  fi
  if [ -n "$ACTIVE_RUNTIME_LOG" ] && [ -f "${ACTIVE_RUNTIME_LOG}.pid" ]; then
    rm -f "${ACTIVE_RUNTIME_LOG}.pid"
  fi
  if [ -n "$ACTIVE_TEST_BUNDLE" ]; then
    xcrun simctl terminate "$SIMULATOR_UDID" "$ACTIVE_TEST_BUNDLE" 2>/dev/null || true
  fi
  ACTIVE_RUNTIME_PID=""
  ACTIVE_RUNTIME_LOG=""
  ACTIVE_TEST_BUNDLE=""
}

trap cleanup_ui_runner EXIT INT TERM

cd "$INTEGRATION"
if ! pod install --silent; then
  echo "[SmokeInfo] FAIL ui_tests pod_install"
  exit 1
fi
cd "$ROOT"

extract_ui_failure() {
  local scheme="$1"
  local xcresult="$2"
  local out_file="$3"
  local runtime_log="$4"
  local json_file
  json_file="$(mktemp)"
  xcrun xcresulttool get --legacy --path "$xcresult" --format json > "$json_file" 2>/dev/null || true
  {
    echo "=== UI failure diagnostics ==="
    echo "run_id=$RUN_ID"
    echo "scheme=$scheme"
    echo "xcresult=$xcresult"
    echo "runtime_log=$runtime_log"
    echo "---"
    python3 - "$json_file" "$runtime_log" <<'PY'
import json, pathlib, re, sys

json_path, runtime_log = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(json_path))
except Exception as exc:
    print(f"xcresult_parse_error={exc}")
    raise SystemExit(0)

failed = []

def walk(node):
    if isinstance(node, dict):
        if node.get("_type", {}).get("_name") == "ActionTestMetadata":
            status = node.get("testStatus", {}).get("_value")
            name = node.get("name", {}).get("_value")
            if status == "Failure" and name:
                failed.append(name)
        for value in node.values():
            walk(value)
    elif isinstance(node, list):
        for item in node:
            walk(item)

walk(data)
for name in failed:
    print(f"failed_test={name}")

log_text = pathlib.Path(runtime_log).read_text(errors="ignore") if pathlib.Path(runtime_log).exists() else ""
for key in ("ad-lifecycle-state", "smoke-last-event", "SmokeVerdict"):
    m = re.findall(rf"{re.escape(key)}[^\n]*", log_text)
    if m:
        print(f"last_{key}={m[-1]}")
if "Terminated due to signal" in log_text or "Fatal error" in log_text:
    print("app_crashed=true")
else:
    print("app_crashed=unknown")
PY
  } > "$out_file"
  rm -f "$json_file"
}

run_ui_scheme() {
  local scheme="$1"
  local log_file="$2"
  local runtime_log="$3"
  local failure_file="$4"
  local xcresult="$ARTIFACTS/${scheme}.xcresult"
  local derived="$DERIVED_UI"
  local lane_rc=0

  cleanup_ui_runner
  rm -rf "$xcresult"
  ARTIFACT_SCHEME="$scheme"
  {
    artifact_header "ui-tests-${scheme}" "xcodebuild test -workspace LegacySmoke.xcworkspace -scheme ${scheme}"
    echo "=== UI tests: $scheme ==="
    echo "run_id=$RUN_ID"
    echo "expected_schema=2"
  } > "$log_file"

  if ! xcodebuild -workspace "$WORKSPACE" -list 2>/dev/null | grep -q "$scheme"; then
    echo "[SmokeInfo] BLOCKED ui_tests scheme_missing=$scheme" >> "$log_file"
    return 2
  fi

  xcrun simctl spawn "$SIMULATOR_UDID" log stream --style compact --predicate 'processImagePath CONTAINS "LegacySmoke" OR processImagePath CONTAINS "BidscubeSDKAppLovinTestApp"' \
    > "$runtime_log" 2>&1 &
  ACTIVE_RUNTIME_PID=$!
  ACTIVE_RUNTIME_LOG="$runtime_log"
  echo "$ACTIVE_RUNTIME_PID" > "${runtime_log}.pid"

  local pods_scheme="Pods-LegacySmoke"
  local test_bundle="com.bidscube.legacysmoke"
  if [ "$scheme" = "ModernSmokeUITests" ]; then
    pods_scheme="Pods-BidscubeSDKAppLovinTestApp"
    test_bundle="com.bidscube.sdktestapp"
  fi
  ACTIVE_TEST_BUNDLE="$test_bundle"

  if ! xcodebuild build \
    -workspace "$WORKSPACE" \
    -scheme "$pods_scheme" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
    -derivedDataPath "$derived" \
    "${XCODE_BUILD_FLAGS[@]}" >> "$log_file" 2>&1; then
    echo "[SmokeInfo] FAIL ui_tests pod_targets_build scheme=$pods_scheme" >> "$log_file"
    lane_rc=65
  fi

  if [ "$lane_rc" -eq 0 ]; then
    set +e
    xcodebuild test \
      -workspace "$WORKSPACE" \
      -scheme "$scheme" \
      -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
      -derivedDataPath "$derived" \
      -resultBundlePath "$xcresult" \
      "${XCODE_BUILD_FLAGS[@]}" \
      >> "$log_file" 2>&1
    lane_rc=$?
    set -e
  fi

  cleanup_ui_runner

  if [ "$lane_rc" -ne 0 ]; then
    extract_ui_failure "$scheme" "$xcresult" "$failure_file" "$runtime_log"
  fi

  echo "ui_exit_code=$lane_rc" >> "$log_file"
  return "$lane_rc"
}

LEGACY_UI=2
MODERN_UI=2

if [ "$UI_TEST_MODE" = "legacy" ] || [ "$UI_TEST_MODE" = "all" ]; then
  set +e
  run_ui_scheme "LegacySmokeUITests" "$ARTIFACTS/ui-tests-legacy.log" "$ARTIFACTS/ui-app-legacy-runtime.log" "$ARTIFACTS/ui-tests-legacy-failure.txt"
  LEGACY_UI=$?
  set -e
fi

if [ "$UI_TEST_MODE" = "modern" ] || [ "$UI_TEST_MODE" = "all" ]; then
  set +e
  run_ui_scheme "ModernSmokeUITests" "$ARTIFACTS/ui-tests-modern.log" "$ARTIFACTS/ui-app-modern-runtime.log" "$ARTIFACTS/ui-tests-modern-failure.txt"
  MODERN_UI=$?
  set -e
fi

{
  echo "=== UI combined summary ==="
  echo "run_id=$RUN_ID"
  echo "legacy_ui_exit_code=$LEGACY_UI"
  echo "modern_ui_exit_code=$MODERN_UI"
  echo "legacy_log=$ARTIFACTS/ui-tests-legacy.log"
  echo "modern_log=$ARTIFACTS/ui-tests-modern.log"
  if [ "$LEGACY_UI" -eq 0 ] && { [ "$UI_TEST_MODE" = "legacy" ] || { [ "$UI_TEST_MODE" = "all" ] && [ "$MODERN_UI" -eq 0 ]; }; }; then
    echo "ui_verdict=PASS"
  elif [ "$LEGACY_UI" -eq 2 ] && [ "$MODERN_UI" -eq 2 ]; then
    echo "ui_verdict=NOT_TESTED"
  else
    echo "ui_verdict=FAIL"
  fi
} > "$ARTIFACTS/ui-tests-combined.log"

if [ "$PARENT_FULL_RUN" != "1" ]; then
  {
    echo "run_id=$RUN_ID"
    echo "legacy_ui_exit_code=$LEGACY_UI"
    echo "modern_ui_exit_code=$MODERN_UI"
  } >> "$ARTIFACTS/test-summary.txt"
fi

if [ "$UI_TEST_MODE" = "legacy" ]; then
  exit "$LEGACY_UI"
fi
if [ "$UI_TEST_MODE" = "modern" ]; then
  exit "$MODERN_UI"
fi

if [ "$LEGACY_UI" -eq 0 ] && [ "$MODERN_UI" -eq 0 ]; then
  exit 0
fi
if [ "$LEGACY_UI" -eq 2 ] && [ "$MODERN_UI" -eq 2 ]; then
  exit 2
fi
exit 1
