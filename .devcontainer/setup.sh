#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$REPO_ROOT/my_flutter_app"

echo "──────────────────────────────────────"
echo "  Dev Container Post-Create Setup"
echo "──────────────────────────────────────"

# ── Install project deps ──────────────────────────────────────
if [ -f "package.json" ]; then
  echo "→ Installing Node deps..."
  npm install
fi

# ── Flutter deps ──────────────────────────────────────────────
if [ -f "$APP_DIR/pubspec.yaml" ]; then
  echo "→ Running flutter pub get in my_flutter_app/..."
  cd "$APP_DIR"
  flutter pub get
fi

# ── Verify ADB can see host's server ─────────────────────────
echo "→ Checking ADB connection..."
adb version
echo "→ Connected devices:"
adb devices

# ── Print SDK info ────────────────────────────────────────────
echo "→ Installed Android SDK components:"
sdkmanager --list_installed

if command -v asterisk >/dev/null 2>&1; then
  echo "→ Asterisk version:"
  asterisk -rx "core show version" || true
fi

echo ""
echo "✓ Setup complete!"
echo "  Phone connected via USB cable should already show above."
echo "  If not, run: adb kill-server && adb start-server && adb devices"