#!/bin/bash
# Remove only whitelisted artifact files before a canonical full run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACTS="$ROOT/artifacts"
mkdir -p "$ARTIFACTS"

WHITELIST=(
  unit-tests.log
  legacy-build.log
  modern-build.log
  client-parity-build.log
  latest-applovin-build.log
  bidscube-simulator-smoke.log
  bidscube-simulator-smoke.log.legacy
  bidscube-simulator-smoke.log.modern
  ui-tests-combined.log
  ui-tests-legacy.log
  ui-tests-modern.log
  ui-app-legacy-runtime.log
  ui-app-modern-runtime.log
  ui-tests-legacy-failure.txt
  ui-tests-modern-failure.txt
  parser-self-tests.log
  pod-lint-modern.log
  pod-lint-legacy.log
  max-tests-combined.log
  max-test-summary.txt
  unity-device-summary.txt
  test-summary.txt
  release-gate-summary.txt
  LegacySmokeUITests.xcresult
  ModernSmokeUITests.xcresult
)

for name in "${WHITELIST[@]}"; do
  rm -rf "$ARTIFACTS/$name"
done

find "$ARTIFACTS" -maxdepth 1 -name '*.pid' -delete 2>/dev/null || true
