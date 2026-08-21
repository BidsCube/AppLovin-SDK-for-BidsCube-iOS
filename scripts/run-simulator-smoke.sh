#!/bin/bash
# Automated simulator smoke with artifact logs.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACTS="$ROOT/artifacts"
INTEGRATION="$ROOT/legacyIntegration"
WORKSPACE="$INTEGRATION/LegacySmoke.xcworkspace"
LOG_FILE="$ARTIFACTS/bidscube-simulator-smoke.log"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
DIRECT_ONLY="${DIRECT_ONLY:-0}"
ALLOW_LEGACY_SMOKE_LOG="${ALLOW_LEGACY_SMOKE_LOG:-0}"
# shellcheck source=artifact-header.sh
source "$ROOT/scripts/artifact-header.sh"
# shellcheck source=smoke-event-utils.sh
source "$ROOT/scripts/smoke-event-utils.sh"
set +e

mkdir -p "$ARTIFACTS"

export RUN_ID="$(date -u +"%Y%m%dT%H%M%SZ")-$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo nogit)"
export PARENT_FULL_RUN=1
export BIDSCUBE_SMOKE_SCHEMA=2
XCODE_BUILD_FLAGS=(ONLY_ACTIVE_ARCH=YES EXCLUDED_ARCHS=x86_64 CODE_SIGNING_ALLOWED=YES)
bash "$ROOT/scripts/clean-artifacts.sh"

DERIVED_LEGACY="/tmp/bidscube-${RUN_ID}-legacy-dd"
DERIVED_MODERN="/tmp/bidscube-${RUN_ID}-modern-dd"
DERIVED_UI="/tmp/bidscube-${RUN_ID}-ui-dd"
rm -rf "$DERIVED_LEGACY" "$DERIVED_MODERN" "$DERIVED_UI"

REQUIRED_SMOKE_EVENTS=(
  smoke_start main_window_probe_install sdk_initialized banner_loaded banner_displayed video_presented video_loaded
  video_displayed dismissal_requested dismissal_verified onAdClosed_received hierarchy_clear complete
)

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

PARSER_SELFTEST_EXIT=1
if run_count_smoke_event_self_tests > "$ARTIFACTS/parser-self-tests.log" 2>&1; then
  PARSER_SELFTEST_EXIT=0
else
  PARSER_SELFTEST_EXIT=$?
fi
echo "parser_selftest_exit_code=$PARSER_SELFTEST_EXIT" | tee -a "$ARTIFACTS/parser-self-tests.log"

{
  artifact_header "bidscube-simulator-smoke" "./scripts/run-simulator-smoke.sh DIRECT_ONLY=${DIRECT_ONLY}"
  echo "=== Bidscube simulator smoke ==="
  echo "run_id=$RUN_ID"
  echo "smoke_schema=2"
  echo "Simulator: $SIMULATOR_UDID"
  echo "Artifacts: $ARTIFACTS"
} | tee "$LOG_FILE"

UNIT_EXIT=1
POD_INSTALL_EXIT=1
CLIENT_PARITY_BUILD_EXIT=1
LEGACY_BUILD_EXIT=1
MODERN_BUILD_EXIT=1
LEGACY_DIRECT_EXIT=1
MODERN_DIRECT_EXIT=1
LEGACY_UI_EXIT=2
MODERN_UI_EXIT=2
LEGACY_APP_SHA256="missing"
MODERN_APP_SHA256="missing"

echo | tee -a "$LOG_FILE"
echo "[1/6] Unit tests..." | tee -a "$LOG_FILE"
if bash "$ROOT/scripts/run-unit-tests.sh"; then
  UNIT_EXIT=0
else
  UNIT_EXIT=$?
fi

echo | tee -a "$LOG_FILE"
echo "[2/6] pod install + build legacy/modern apps..." | tee -a "$LOG_FILE"
cd "$INTEGRATION"
if pod install --silent; then
  POD_INSTALL_EXIT=0
else
  POD_INSTALL_EXIT=$?
fi

echo | tee -a "$LOG_FILE"
echo "[2b/6] Client parity pod install (AppLovin 13.2.0 exact)..." | tee -a "$LOG_FILE"
export APPLOVIN_REQUESTED_VERSION="13.2.0"
CLIENT_PARITY_LOG="$ARTIFACTS/client-parity-build.log"
{
  artifact_header "client-parity-build" "pod install + xcodebuild LegacySmoke with AppLovinSDK 13.2.0"
  echo "applovin_requested_version=13.2.0"
} > "$CLIENT_PARITY_LOG"
cp Podfile Podfile.rc-default
rm -f Podfile.lock
cp Podfile.client-parity Podfile
if pod install >> "$CLIENT_PARITY_LOG" 2>&1; then
  RESOLVED="$(grep -E '^  - AppLovinSDK \(' Pods/Manifest.lock | sed -n 's/.*(\(.*\)).*/\1/p' | head -1)"
  echo "applovin_resolved_version=$RESOLVED" >> "$CLIENT_PARITY_LOG"
  if [ "$RESOLVED" = "13.2.0" ] \
     && xcodebuild build \
       -workspace "$WORKSPACE" \
       -scheme LegacySmoke \
       -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
       -derivedDataPath "/tmp/bidscube-${RUN_ID}-client-parity-dd" \
       "${XCODE_BUILD_FLAGS[@]}" >> "$CLIENT_PARITY_LOG" 2>&1; then
    CLIENT_PARITY_BUILD_EXIT=0
  fi
fi
mv Podfile.rc-default Podfile
rm -f Podfile.lock
pod install --silent >> "$CLIENT_PARITY_LOG" 2>&1 || true
export APPLOVIN_REQUESTED_VERSION="~> 13.2"
export APPLOVIN_RESOLVED_VERSION="$(awk '/- AppLovinSDK \(/ {print $2; exit}' Pods/Manifest.lock | tr -d '()')"

build_host_app() {
  local scheme="$1"
  local pods_scheme="$2"
  local derived="$3"
  local log_file="$4"
  local build_started_at
  build_started_at="$(date +%s)"

  {
    artifact_header "${scheme}-build" "xcodebuild build -scheme ${scheme}"
    echo "${scheme}_build_started_at=$build_started_at"
  } > "$log_file"

  if ! xcodebuild build \
    -workspace "$WORKSPACE" \
    -scheme "$pods_scheme" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
    -derivedDataPath "$derived" \
    "${XCODE_BUILD_FLAGS[@]}" >> "$log_file" 2>&1; then
    echo 1
    return
  fi

  if xcodebuild build \
    -workspace "$WORKSPACE" \
    -scheme "$scheme" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
    -derivedDataPath "$derived" \
    "${XCODE_BUILD_FLAGS[@]}" >> "$log_file" 2>&1; then
    echo 0
  else
    echo $?
  fi
}

LEGACY_BUILD_STARTED_AT="$(date +%s)"
MODERN_BUILD_STARTED_AT="$(date +%s)"
LEGACY_BUILD_EXIT="$(build_host_app LegacySmoke Pods-LegacySmoke "$DERIVED_LEGACY" "$ARTIFACTS/legacy-build.log" || echo 1)"
MODERN_BUILD_EXIT="$(build_host_app BidscubeSDKAppLovinTestApp Pods-BidscubeSDKAppLovinTestApp "$DERIVED_MODERN" "$ARTIFACTS/modern-build.log" || echo 1)"

LEGACY_APP="$DERIVED_LEGACY/Build/Products/Debug-iphonesimulator/LegacySmoke.app"
MODERN_APP="$DERIVED_MODERN/Build/Products/Debug-iphonesimulator/BidscubeSDKAppLovinTestApp.app"

if [ "$LEGACY_BUILD_EXIT" -eq 0 ]; then
  if verify_app_freshness "$LEGACY_APP" "$LEGACY_BUILD_STARTED_AT" "com.bidscube.legacysmoke" >> "$ARTIFACTS/legacy-build.log" 2>&1; then
    LEGACY_APP_SHA256="$(sha256_file "$LEGACY_APP/Info.plist")"
  else
    LEGACY_BUILD_EXIT=1
  fi
fi
if [ "$MODERN_BUILD_EXIT" -eq 0 ]; then
  if verify_app_freshness "$MODERN_APP" "$MODERN_BUILD_STARTED_AT" "com.bidscube.sdktestapp" >> "$ARTIFACTS/modern-build.log" 2>&1; then
    MODERN_APP_SHA256="$(sha256_file "$MODERN_APP/Info.plist")"
  else
    MODERN_BUILD_EXIT=1
  fi
fi

xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true

run_smoke_app() {
  local label="$1"
  local bundle="$2"
  local app_path="$3"
  local build_exit="$4"
  local timeout="$5"

  echo | tee -a "$LOG_FILE"
  echo "[smoke] $label build_exit=$build_exit" | tee -a "$LOG_FILE"
  local app_log="$ARTIFACTS/bidscube-simulator-smoke.log.$label"
  {
    artifact_header "bidscube-simulator-smoke.$label" "simctl launch $bundle -AutoVerifyFullSmoke"
    echo "expected_run_id=$RUN_ID"
    echo "expected_schema=2"
  } > "$app_log"

  if [ "$build_exit" -ne 0 ] || [ ! -d "$app_path" ]; then
    echo "  skipped: build failed or app missing" | tee -a "$LOG_FILE"
    echo "direct_skipped reason=build_failed" >> "$app_log"
    return 1
  fi

  xcrun simctl terminate "$SIMULATOR_UDID" "$bundle" 2>/dev/null || true
  xcrun simctl install "$SIMULATOR_UDID" "$app_path"

  export SIMCTL_CHILD_BIDSCUBE_SMOKE_RUN_ID="$RUN_ID"
  export SIMCTL_CHILD_BIDSCUBE_SMOKE_SCHEMA="2"

  (
    xcrun simctl launch --console-pty "$SIMULATOR_UDID" "$bundle" -AutoVerifyFullSmoke 2>&1 | tee -a "$app_log"
  ) &
  local launch_pid=$!

  local waited=0
  while [ "$waited" -lt "$timeout" ]; do
    if log_has_current_schema2_run "$app_log" "$RUN_ID" "$label" \
      && grep -q "\\[SmokeVerdict\\].*run_id=${RUN_ID}.*schema=2.*label=${label}.*event=complete.*status=PASS" "$app_log" 2>/dev/null; then
      break
    fi
    if grep -q "\\[SmokeVerdict\\].*run_id=${RUN_ID}.*schema=2.*label=${label}.*event=complete.*status=FAIL" "$app_log" 2>/dev/null; then
      break
    fi
    if [ "$ALLOW_LEGACY_SMOKE_LOG" = "1" ] && log_has_legacy_complete_format "$app_log" "$label"; then
      break
    fi
    sleep 2
    waited=$((waited + 2))
  done

  kill "$launch_pid" 2>/dev/null || true
  wait "$launch_pid" 2>/dev/null || true
  cat "$app_log" >> "$LOG_FILE" || true
  xcrun simctl terminate "$SIMULATOR_UDID" "$bundle" 2>/dev/null || true

  if log_has_current_schema2_run "$app_log" "$RUN_ID" "$label" \
    && grep -q "\\[SmokeVerdict\\].*run_id=${RUN_ID}.*schema=2.*label=${label}.*event=complete.*status=PASS" "$app_log" 2>/dev/null; then
    echo "  finished PASS in ${waited}s" | tee -a "$LOG_FILE"
    return 0
  fi
  echo "  finished FAIL/timeout in ${waited}s" | tee -a "$LOG_FILE"
  return 1
}

score_app_log() {
  local label="$1"
  local file="$2"
  local fail=0

  if [ "$ALLOW_LEGACY_SMOKE_LOG" = "1" ] && log_has_legacy_complete_format "$file" "$label"; then
    echo "$label legacy_format_only: WARN"
  fi

  if ! log_has_current_schema2_run "$file" "$RUN_ID" "$label"; then
    echo "$label schema2_run: FAIL"
    return 1
  fi

  local session
  if ! session="$(extract_smoke_session "$file" "$RUN_ID" "$label")"; then
    echo "$label session: FAIL"
    return 1
  fi
  echo "$label session=$session"

  if grep -q "\\[SmokeVerdict\\].*run_id=${RUN_ID}.*schema=2.*label=${label}.*status=FAIL" "$file" 2>/dev/null; then
    echo "$label structured FAIL events present"
    fail=1
  fi

  for event in "${REQUIRED_SMOKE_EVENTS[@]}"; do
    local count
    count="$(count_smoke_event "$file" "$RUN_ID" "$session" "$label" "$event" "PASS")"
    if ! [[ "$count" =~ ^[0-9]+$ ]]; then
      echo "$label ${event}_count_parser_error"
      fail=1
      continue
    fi
    if [ "$count" -ne 1 ]; then
      echo "$label ${event}_count=$count: FAIL"
      fail=1
    else
      echo "$label ${event}_count=$count: PASS"
    fi
  done

  if [ "$label" = "legacy" ]; then
    for event in native_loaded native_displayed; do
      local count
      count="$(count_smoke_event "$file" "$RUN_ID" "$session" "$label" "$event" "PASS")"
      if [ "$count" -ne 1 ]; then fail=1; echo "$label ${event}_count=$count: FAIL"; fi
    done
  fi

  local dup
  dup="$(count_smoke_event "$file" "$RUN_ID" "$session" "$label" "duplicate_event" "FAIL")"
  if [ "$dup" -gt 0 ]; then
    echo "$label duplicate_event_count=$dup: FAIL"
    fail=1
  fi

  return "$fail"
}

echo | tee -a "$LOG_FILE"
echo "[3/6] Legacy direct smoke..." | tee -a "$LOG_FILE"
if run_smoke_app "legacy" "com.bidscube.legacysmoke" "$LEGACY_APP" "$LEGACY_BUILD_EXIT" 120; then
  LEGACY_DIRECT_EXIT=0
fi

echo | tee -a "$LOG_FILE"
echo "[4/6] Modern direct smoke..." | tee -a "$LOG_FILE"
if run_smoke_app "modern" "com.bidscube.sdktestapp" "$MODERN_APP" "$MODERN_BUILD_EXIT" 120; then
  MODERN_DIRECT_EXIT=0
fi

if [ "$DIRECT_ONLY" != "1" ]; then
  echo | tee -a "$LOG_FILE"
  echo "[5/6] UI tests..." | tee -a "$LOG_FILE"
  export DERIVED_UI
  bash "$ROOT/scripts/run-ui-tests.sh" || true
  if [ -f "$ARTIFACTS/ui-tests-legacy.log" ]; then
    LEGACY_UI_EXIT="$(grep '^ui_exit_code=' "$ARTIFACTS/ui-tests-legacy.log" | tail -1 | cut -d= -f2 || echo 1)"
  fi
  if [ -f "$ARTIFACTS/ui-tests-modern.log" ]; then
    MODERN_UI_EXIT="$(grep '^ui_exit_code=' "$ARTIFACTS/ui-tests-modern.log" | tail -1 | cut -d= -f2 || echo 1)"
  fi
else
  echo | tee -a "$LOG_FILE"
  echo "[5/6] UI tests skipped (DIRECT_ONLY=1)" | tee -a "$LOG_FILE"
  LEGACY_UI_EXIT=2
  MODERN_UI_EXIT=2
fi

STRUCTURED_VIOLATION_COUNT="$(structured_violation_count "$ARTIFACTS/bidscube-simulator-smoke.log.legacy" "$ARTIFACTS/bidscube-simulator-smoke.log.modern" "$LOG_FILE")"
if ! [[ "$STRUCTURED_VIOLATION_COUNT" =~ ^[0-9]+$ ]]; then
  STRUCTURED_VIOLATION_COUNT=999
fi

echo | tee -a "$LOG_FILE"
echo "=== Verdict ===" | tee -a "$LOG_FILE"
score_app_log legacy "$ARTIFACTS/bidscube-simulator-smoke.log.legacy" | tee -a "$LOG_FILE" || LEGACY_DIRECT_EXIT=1
score_app_log modern "$ARTIFACTS/bidscube-simulator-smoke.log.modern" | tee -a "$LOG_FILE" || MODERN_DIRECT_EXIT=1

OVERALL=1
if [ "$PARSER_SELFTEST_EXIT" -eq 0 ] \
   && [ "$POD_INSTALL_EXIT" -eq 0 ] \
   && [ "$CLIENT_PARITY_BUILD_EXIT" -eq 0 ] \
   && [ "$UNIT_EXIT" -eq 0 ] \
   && [ "$LEGACY_BUILD_EXIT" -eq 0 ] \
   && [ "$MODERN_BUILD_EXIT" -eq 0 ] \
   && [ "$LEGACY_DIRECT_EXIT" -eq 0 ] \
   && [ "$MODERN_DIRECT_EXIT" -eq 0 ] \
   && { [ "$DIRECT_ONLY" = "1" ] || { [ "$LEGACY_UI_EXIT" -eq 0 ] && [ "$MODERN_UI_EXIT" -eq 0 ]; }; } \
   && [ "$STRUCTURED_VIOLATION_COUNT" -eq 0 ]; then
  OVERALL=0
fi

SDK_VERSION="$(grep -m1 'sdkVersion' "$ROOT/bidscubeSdk/Core/Constants.swift" 2>/dev/null | sed 's/.*= //;s/ //g' || echo unknown)"
RC_SOURCE_SHA256="$(compute_rc_source_sha256 2>/dev/null || echo unknown)"
{
  echo "run_id=$RUN_ID"
  echo "rc_source_sha256=$RC_SOURCE_SHA256"
  echo "smoke_schema=2"
  echo "git_commit=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "sdk_version=$SDK_VERSION"
  echo "simulator_udid=$SIMULATOR_UDID"
  echo "parser_selftest_exit_code=$PARSER_SELFTEST_EXIT"
  echo "pod_install_exit_code=$POD_INSTALL_EXIT"
  echo "client_parity_build_exit_code=$CLIENT_PARITY_BUILD_EXIT"
  echo "applovin_requested_version=13.2.0"
  echo "applovin_resolved_version_client_parity=$(grep '^applovin_resolved_version=' "$CLIENT_PARITY_LOG" 2>/dev/null | tail -1 | cut -d= -f2 || echo unknown)"
  echo "unit_exit_code=$UNIT_EXIT"
  echo "legacy_build_exit_code=$LEGACY_BUILD_EXIT"
  echo "modern_build_exit_code=$MODERN_BUILD_EXIT"
  echo "legacy_app_sha256=$LEGACY_APP_SHA256"
  echo "modern_app_sha256=$MODERN_APP_SHA256"
  echo "legacy_direct_exit_code=$LEGACY_DIRECT_EXIT"
  echo "modern_direct_exit_code=$MODERN_DIRECT_EXIT"
  echo "legacy_ui_exit_code=$LEGACY_UI_EXIT"
  echo "modern_ui_exit_code=$MODERN_UI_EXIT"
  echo "structured_violation_count=$STRUCTURED_VIOLATION_COUNT"
  echo "duplicate_summary_keys_count=0"
  echo "max_legacy_exit_code=2"
  echo "max_modern_exit_code=2"
  echo "max_live_gate=BLOCKED"
  echo "unity_device_gate=NOT_TESTED"
  echo "local_simulator_gate=$([ "$OVERALL" -eq 0 ] && echo PASS || echo FAIL)"
  echo "release_gate=NOT_READY"
  echo "overall_exit_code=$OVERALL"
} > "$ARTIFACTS/test-summary.txt"

echo | tee -a "$LOG_FILE"
if [ "$OVERALL" -eq 0 ]; then
  echo "Local RC readiness for MAX/Unity QA: READY" | tee -a "$LOG_FILE"
else
  echo "Local RC readiness for MAX/Unity QA: NOT READY" | tee -a "$LOG_FILE"
fi
echo "Release readiness: NOT READY" | tee -a "$LOG_FILE"
echo "MAX mediation: SKIPPED (no credentials — exit 2 via ./scripts/run-max-smoke.sh)" | tee -a "$LOG_FILE"
echo "Unity physical-device input: NOT TESTED" | tee -a "$LOG_FILE"

exit "$OVERALL"
