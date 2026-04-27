#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXPECTED_DIR="$SCRIPT_DIR/../expected"
EVENT_LOG="/tmp/sip_simulation_events.log"
MODE="${1:-all}"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

info() {
  echo "[INFO] $1"
}

require_match() {
  local output="$1"
  local regex="$2"
  local message="$3"
  if ! grep -Eq "$regex" <<<"$output"; then
    fail "$message"
  fi
}

verify_ordered_states() {
  local expected_file="$1"
  local grep_prefix="$2"

  mapfile -t expected_states < "$expected_file"
  local previous_line=0
  local state
  for state in "${expected_states[@]}"; do
    local current_line
    local pattern="^${state}\\|"
    if [[ -n "$grep_prefix" ]]; then
      pattern="^${state}\\|.*${grep_prefix}"
    fi
    current_line="$(grep -nE "$pattern" "$EVENT_LOG" | head -n 1 | cut -d: -f1 || true)"
    if [[ -z "$current_line" ]]; then
      fail "Missing expected state '$state' for filter '${grep_prefix}' in $EVENT_LOG"
    fi
    if (( current_line <= previous_line )); then
      fail "State '$state' is out of order for filter '${grep_prefix}' in $EVENT_LOG"
    fi
    previous_line="$current_line"
  done
}

wait_for_log_pattern() {
  local regex="$1"
  local timeout_seconds="$2"

  local start_ts
  start_ts="$(date +%s)"

  while true; do
    if grep -Eq "$regex" "$EVENT_LOG"; then
      break
    fi

    local now_ts
    now_ts="$(date +%s)"
    if (( now_ts - start_ts > timeout_seconds )); then
      fail "Timeout waiting for '$regex'. See $EVENT_LOG"
    fi
    sleep 0.2
  done
}

run_happy_path() {
  info "Running happy-path simulation"
  asterisk -rx "channel originate Local/9100@sip-sim extension 9101@sip-sim" >/dev/null
  wait_for_log_pattern '^ENDED\|' 20
  verify_ordered_states "$EXPECTED_DIR/flutter_call_state_order.txt" ""

  if ! grep -q '^CONFIRMED|leg=callee' "$EVENT_LOG"; then
    fail "Callee leg was not confirmed in happy-path simulation"
  fi
}

run_failure_paths() {
  info "Running failure-path simulations (busy, no-answer, registration-fail)"

  asterisk -rx "channel originate Local/9200@sip-sim application Wait 1" >/dev/null
  wait_for_log_pattern '^ENDED\|scenario=busy' 10
  verify_ordered_states "$EXPECTED_DIR/failure_busy_order.txt" "scenario=busy"

  asterisk -rx "channel originate Local/9201@sip-sim application Wait 1" >/dev/null
  wait_for_log_pattern '^ENDED\|scenario=no_answer' 10
  verify_ordered_states "$EXPECTED_DIR/failure_no_answer_order.txt" "scenario=no_answer"

  asterisk -rx "channel originate Local/9202@sip-sim application Wait 1" >/dev/null
  wait_for_log_pattern '^REGISTRATION_FAILED\|scenario=registration_fail' 10
  verify_ordered_states "$EXPECTED_DIR/failure_registration_order.txt" "scenario=registration_fail"
}

if ! command -v asterisk >/dev/null 2>&1; then
  fail "Asterisk is not installed in this environment."
fi

if ! asterisk -rx "core show uptime" >/dev/null 2>&1; then
  info "Asterisk is not running, attempting to start it from devcontainer helper..."
  if [[ -x "$REPO_ROOT/.devcontainer/start-asterisk.sh" ]]; then
    "$REPO_ROOT/.devcontainer/start-asterisk.sh"
  else
    fail "Asterisk not running and start helper not found at .devcontainer/start-asterisk.sh"
  fi
fi

info "Reloading Asterisk dialplan and PJSIP configuration"
asterisk -rx "dialplan reload" >/dev/null
asterisk -rx "pjsip reload" >/dev/null

transport_output="$(asterisk -rx "pjsip show transports")"
endpoint_1001_output="$(asterisk -rx "pjsip show endpoint 1001")"
endpoint_1002_output="$(asterisk -rx "pjsip show endpoint 1002")"

require_match "$transport_output" "transport-ws|0\\.0\\.0\\.0:8088|ws" "WebSocket transport is missing in Asterisk"
require_match "$endpoint_1001_output" "Endpoint: +1001" "Asterisk endpoint 1001 is missing"
require_match "$endpoint_1002_output" "Endpoint: +1002" "Asterisk endpoint 1002 is missing"

rm -f "$EVENT_LOG"
touch "$EVENT_LOG"
chmod 666 "$EVENT_LOG"

case "$MODE" in
  happy)
    run_happy_path
    ;;
  failure)
    run_failure_paths
    ;;
  all)
    run_happy_path
    run_failure_paths
    ;;
  *)
    fail "Unknown mode '$MODE'. Use: happy | failure | all"
    ;;
esac

echo
info "Simulation verified successfully (mode=$MODE)"
info "Event log: $EVENT_LOG"
cat "$EVENT_LOG"
