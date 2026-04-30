#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

info() {
  echo "[INFO] $1"
}

if ! command -v asterisk >/dev/null 2>&1; then
  fail "Asterisk is not installed"
fi

if ! asterisk -rx "core show uptime" >/dev/null 2>&1; then
  info "Starting Asterisk from devcontainer helper"
  "$REPO_ROOT/.devcontainer/start-asterisk.sh"
fi

asterisk -rx "pjsip reload" >/dev/null
asterisk -rx "dialplan reload" >/dev/null

transport_output="$(asterisk -rx "pjsip show transports")"
endpoint_ws_1001="$(asterisk -rx "pjsip show endpoint 1001")"
endpoint_ws_1002="$(asterisk -rx "pjsip show endpoint 1002")"
endpoint_udp_2001="$(asterisk -rx "pjsip show endpoint 2001")"
endpoint_udp_2002="$(asterisk -rx "pjsip show endpoint 2002")"

if ! grep -Eq 'transport-ws|0\.0\.0\.0:8088|ws' <<<"$transport_output"; then
  fail "WS transport is not active on port 8088"
fi

if ! grep -Eq 'transport-udp|0\.0\.0\.0:5060|udp' <<<"$transport_output"; then
  fail "UDP transport is not active on port 5060"
fi

for output in "$endpoint_ws_1001" "$endpoint_ws_1002" "$endpoint_udp_2001" "$endpoint_udp_2002"; do
  if ! grep -Eq 'Endpoint:' <<<"$output"; then
    fail "One or more required endpoints are missing"
  fi
done

if command -v ss >/dev/null 2>&1; then
  info "Listening sockets relevant to SIP"
  ss -lunpt | grep -E ':(5060|8088|10000|20000)\b' || true
fi

host_ips="$(hostname -I 2>/dev/null | xargs || true)"

echo
info "LAN preflight passed"
if [[ -n "$host_ips" ]]; then
  info "Host/container IP candidates: $host_ips"
fi
info "Use this in Android app settings:"
info "Server = <LAN_IP>, Transport = WS, Port = 8088"
info "For PC softphone (UDP): username 2001/2002, port 5060"
