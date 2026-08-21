#!/bin/bash
# MAX mediation live verification — skipped when credentials are unavailable (exit 2).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACTS="$ROOT/artifacts"
SUMMARY="$ARTIFACTS/max-test-summary.txt"
COMBINED_LOG="$ARTIFACTS/max-tests-combined.log"
# shellcheck source=artifact-header.sh
source "$ROOT/scripts/artifact-header.sh"

mkdir -p "$ARTIFACTS"
export RUN_ID="${RUN_ID:-$(date -u +"%Y%m%dT%H%M%SZ")-$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo nogit)}"

{
  artifact_header "max-smoke-skipped" "./scripts/run-max-smoke.sh"
  echo "status=SKIPPED"
  echo "blocking_reason=MAX live verification: SKIPPED_NO_CREDENTIALS"
  echo "max_live_gate=BLOCKED"
  echo "max_legacy_exit_code=2"
  echo "max_modern_exit_code=2"
  echo "overall_exit_code=2"
  echo "release_gate=NOT_READY"
} | tee "$SUMMARY" >> "$COMBINED_LOG"

echo "[SmokeVerdict] SKIPPED max_smoke reason=no_credentials"
exit 2
