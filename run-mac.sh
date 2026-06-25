#!/usr/bin/env bash
# Build L'Envers (Debug) for native macOS, sign it, and launch it.
#
# L'Envers is a windowed reverse-outliner. It calls Anthropic directly with the
# key you paste in Réglages (stored in the Keychain). First run shows a light
# onboarding explainer.
#
# Keep DerivedData OUT of any iCloud-synced folder or `codesign` fails
# ("resource fork … not allowed").
set -euo pipefail
cd "$(dirname "$0")"

DD="${LENVERS_MAC_DD:-/tmp/l-envers-mac-dd}"   # DerivedData OUTSIDE iCloud

echo "==> Generating project…"
{ ./gen.sh >/dev/null 2>&1 || /opt/homebrew/bin/xcodegen generate >/dev/null; }

echo "==> Building (Debug) + signing for macOS…"
xcodebuild -project LEnvers.xcodeproj -scheme "LEnvers" \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath "$DD" build

APP="$DD/Build/Products/Debug/LEnvers.app"
[[ -d "$APP" ]] || { echo "Build product not found at $APP" >&2; exit 1; }

echo "==> Launching $APP"
open "$APP"

echo
echo "==> L'Envers (macOS) launched."
echo "    Paste your Anthropic API key in Réglages on first run, then"
echo "    coller un texte → Radiographier."
