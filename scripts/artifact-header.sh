#!/bin/bash
# Emit standard artifact header for smoke/unit/UI logs.
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_ARTIFACT_ROOT="$(cd "$_SCRIPT_DIR/.." && pwd)"

compute_git_diff_sha256() {
  {
    git -C "$_ARTIFACT_ROOT" diff HEAD 2>/dev/null || true
    git -C "$_ARTIFACT_ROOT" diff --cached 2>/dev/null || true
  } | shasum -a 256 | awk '{print $1}'
}

compute_rc_source_sha256() {
  {
    git -C "$_ARTIFACT_ROOT" diff HEAD 2>/dev/null || true
    git -C "$_ARTIFACT_ROOT" diff --cached 2>/dev/null || true
    git -C "$_ARTIFACT_ROOT" ls-files --others --exclude-standard \
      bidscubeSdk legacyIntegration scripts \
      *.podspec Package.swift spmUnitTests CHANGELOG.md 2>/dev/null \
      | while read -r path; do
          [ -f "$_ARTIFACT_ROOT/$path" ] && cat "$_ARTIFACT_ROOT/$path"
        done
  } | shasum -a 256 | awk '{print $1}'
}

artifact_header() {
  local label="$1"
  local command="$2"
  local sim_name="${SIMULATOR_NAME:-unknown}"
  if [ -n "${SIMULATOR_UDID:-}" ] && [ "$sim_name" = "unknown" ]; then
    sim_name="$(xcrun simctl list devices "$SIMULATOR_UDID" 2>/dev/null | sed -n 's/^[[:space:]]*\(.*\) (.*/\1/p' | head -1 || echo unknown)"
  fi
  local applovin_requested="${APPLOVIN_REQUESTED_VERSION:-~> 13.2}"
  local applovin_resolved="${APPLOVIN_RESOLVED_VERSION:-unknown}"
  local ima_resolved="${IMA_RESOLVED_VERSION:-unknown}"
  if [ "$applovin_resolved" = "unknown" ] && [ -f "$_ARTIFACT_ROOT/legacyIntegration/Pods/Manifest.lock" ]; then
    applovin_resolved="$(awk '/- AppLovinSDK \(/ {print $2; exit}' "$_ARTIFACT_ROOT/legacyIntegration/Pods/Manifest.lock" | tr -d '()')"
  fi
  {
    echo "=== artifact: $label ==="
    echo "run_id: ${RUN_ID:-unset}"
    echo "timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "git_commit: $(git -C "$_ARTIFACT_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "git_status_short:"
    git -C "$_ARTIFACT_ROOT" status --short 2>/dev/null || true
    echo "git_diff_sha256: $(compute_git_diff_sha256)"
    echo "rc_source_sha256: $(compute_rc_source_sha256)"
    echo "archive_sha256: $(shasum -a 256 "$_ARTIFACT_ROOT"/*.podspec 2>/dev/null | shasum -a 256 | awk '{print $1}' || echo unknown)"
    echo "sdk_version: $(grep -m1 'sdkVersion' "$_ARTIFACT_ROOT/bidscubeSdk/Core/Constants.swift" 2>/dev/null | sed 's/.*= //;s/ //g' || echo unknown)"
    echo "applovin_requested_version: $applovin_requested"
    echo "applovin_resolved_version: $applovin_resolved"
    echo "ima_resolved_version: $ima_resolved"
    echo "simulator_name: $sim_name"
    echo "simulator_udid: ${SIMULATOR_UDID:-auto}"
    echo "simulator_runtime: ${SIMULATOR_RUNTIME:-unknown}"
    echo "scheme: ${ARTIFACT_SCHEME:-n/a}"
    echo "command: $command"
    echo "---"
  }
}
