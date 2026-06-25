#!/usr/bin/env bash
# Regenerate LEnvers.xcodeproj from project.yml (the .xcodeproj is gitignored).
# Requires XcodeGen: brew install xcodegen
set -euo pipefail
cd "$(dirname "$0")"
/opt/homebrew/bin/xcodegen generate
echo "Generated LEnvers.xcodeproj — build with:"
echo "  xcodebuild -scheme LEnvers -destination 'platform=macOS' build"
