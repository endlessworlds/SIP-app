#!/usr/bin/env bash
set -euo pipefail

if pgrep -x asterisk >/dev/null 2>&1; then
  echo "[devcontainer] Asterisk already running"
  exit 0
fi

ASTERISK_CONF="asterisk.conf"
if [ -f "/etc/asterisk/asterisk.conf" ]; then
  ASTERISK_CONF="/etc/asterisk/asterisk.conf"
fi

ASTERISK_USER="root"
ASTERISK_GROUP="root"
if id -u asterisk >/dev/null 2>&1; then
  ASTERISK_USER="asterisk"
  ASTERISK_GROUP="asterisk"
fi

echo "[devcontainer] Starting Asterisk in background..."

if command -v adb >/dev/null 2>&1; then
  adb reverse tcp:5060 tcp:5060 >/dev/null 2>&1 || true
  adb reverse tcp:8088 tcp:8088 >/dev/null 2>&1 || true
  echo "[devcontainer] adb reverse tcp:5060 -> tcp:5060"
  echo "[devcontainer] adb reverse tcp:8088 -> tcp:8088"
fi

asterisk -C "$ASTERISK_CONF" -f -U "$ASTERISK_USER" -G "$ASTERISK_GROUP" \
  >/tmp/asterisk.log 2>&1 &

sleep 1
if ! asterisk -rx "core show uptime" >/dev/null 2>&1; then
  echo "[devcontainer] Failed to start Asterisk. See /tmp/asterisk.log"
  exit 1
fi

echo "[devcontainer] Asterisk started"