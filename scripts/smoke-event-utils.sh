#!/bin/bash
# Shared smoke scoring helpers for simulator smoke runners.
set -uo pipefail

smoke_schema_default() {
  echo "2"
}

count_smoke_event() {
  local file="$1"
  local run_id="$2"
  local session="$3"
  local label="$4"
  local event="$5"
  local event_status="${6:-PASS}"

  if [ ! -f "$file" ]; then
    echo 0
    return
  fi

  awk \
    -v run_id="$run_id" \
    -v session="$session" \
    -v label="$label" \
    -v event="$event" \
    -v status="$event_status" \
    '
      index($0, "[SmokeVerdict]") &&
      index($0, "run_id=" run_id) &&
      index($0, "schema=2") &&
      index($0, "session=" session) &&
      index($0, "label=" label) &&
      index($0, "event=" event) &&
      index($0, "status=" status) {
        count++
      }
      END { print count + 0 }
    ' "$file"
}

extract_smoke_session() {
  local file="$1"
  local run_id="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    return 1
  fi

  local session
  session="$(
    grep -E "\\[SmokeVerdict\\].*run_id=${run_id}.*schema=2.*label=${label}.*event=smoke_start.*status=PASS" "$file" \
      | head -1 \
      | sed -n 's/.*session=\([^ ]*\).*/\1/p'
  )"
  if [ -z "$session" ]; then
    return 1
  fi
  echo "$session"
}

log_has_current_schema2_run() {
  local file="$1"
  local run_id="$2"
  local label="$3"

  grep -q "\\[SmokeVerdict\\].*run_id=${run_id}.*schema=2.*label=${label}.*event=smoke_start.*status=PASS" "$file" 2>/dev/null
}

log_has_legacy_complete_format() {
  local file="$1"
  local label="$2"
  grep -q "\\[SmokeVerdict\\] COMPLETE ${label} PASS" "$file" 2>/dev/null
}

structured_violation_count() {
  local legacy_log="$1"
  local modern_log="$2"
  local master_log="$3"
  grep -Eh '\\[SmokeVerdict\\].*status=FAIL|lifecycle_violation|duplicate_requestAds|container replacement|dismissal_failed|stillVisible|noDismissPath' \
    "$legacy_log" "$modern_log" "$master_log" 2>/dev/null \
    | wc -l \
    | tr -d '[:space:]'
}

sha256_file() {
  local file="$1"
  if [ ! -e "$file" ]; then
    echo "missing"
    return
  fi
  shasum -a 256 "$file" | awk '{print $1}'
}

verify_app_freshness() {
  local app_path="$1"
  local build_started_at="$2"
  local bundle_id="$3"

  if [ ! -d "$app_path" ]; then
    echo "missing_app"
    return 1
  fi

  local mtime
  mtime="$(stat -f '%m' "$app_path")"
  if [ "$mtime" -lt "$build_started_at" ]; then
    echo "stale_app mtime=$mtime started=$build_started_at"
    return 1
  fi

  local actual_bundle
  actual_bundle="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Info.plist" 2>/dev/null || echo unknown)"
  if [ "$actual_bundle" != "$bundle_id" ]; then
    echo "bundle_mismatch expected=$bundle_id actual=$actual_bundle"
    return 1
  fi

  echo "fresh"
  return 0
}

run_count_smoke_event_self_tests() {
  local fixture failures=0 one_event_fixture
  fixture="$(mktemp)"
  one_event_fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
[SmokeVerdict] run_id=run-a schema=2 session=sess-a label=legacy event=smoke_start status=PASS
[SmokeVerdict] run_id=run-a schema=2 session=sess-a label=legacy event=smoke_start status=PASS
human readable line smoke_start PASS
[SmokeVerdict] run_id=run-b schema=2 session=sess-a label=legacy event=smoke_start status=PASS
[SmokeVerdict] run_id=run-a schema=2 session=sess-b label=legacy event=smoke_start status=PASS
[SmokeVerdict] run_id=run-a schema=2 session=sess-a label=modern event=smoke_start status=PASS
EOF
  head -1 "$fixture" > "$one_event_fixture"

  assert_count() {
    local expected="$1"
    local actual="$2"
    local name="$3"
    if [ "$actual" != "$expected" ]; then
      echo "SELFTEST FAIL $name expected=$expected actual=$actual"
      failures=$((failures + 1))
    else
      echo "SELFTEST PASS $name=$actual"
    fi
  }

  assert_count 0 "$(count_smoke_event "$fixture" run-a sess-a legacy complete PASS)" no_event
  assert_count 1 "$(count_smoke_event "$one_event_fixture" run-a sess-a legacy smoke_start PASS)" one_event
  assert_count 2 "$(count_smoke_event "$fixture" run-a sess-a legacy smoke_start PASS)" two_identical_real_events
  assert_count 0 "$(count_smoke_event "$fixture" run-a sess-a legacy smoke_start FAIL)" wrong_status
  assert_count 0 "$(count_smoke_event "$fixture" run-a sess-a legacy unknown-event PASS)" unknown_event
  assert_count 0 "$(count_smoke_event "$fixture" unknown-run sess-a legacy smoke_start PASS)" other_run_id
  assert_count 0 "$(count_smoke_event "$fixture" run-a unknown-session legacy smoke_start PASS)" other_session
  assert_count 0 "$(count_smoke_event "$fixture" run-a sess-a unknown-label smoke_start PASS)" other_label
  assert_count 1 "$(count_smoke_event "$fixture" run-b sess-a legacy smoke_start PASS)" matching_other_run
  assert_count 1 "$(count_smoke_event "$fixture" run-a sess-b legacy smoke_start PASS)" matching_other_session
  assert_count 1 "$(count_smoke_event "$fixture" run-a sess-a modern smoke_start PASS)" matching_other_label

  rm -f "$fixture" "$one_event_fixture"
  if [ "$failures" -gt 0 ]; then
    return 1
  fi
  return 0
}
