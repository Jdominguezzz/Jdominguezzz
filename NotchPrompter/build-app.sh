#!/usr/bin/env bash
# Builds NotchPrompter.app into ./build and (optionally) copies it to /Applications.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

APP="build/NotchPrompter.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/NotchPrompter" "$APP/Contents/MacOS/NotchPrompter"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Ad-hoc sign so macOS will launch it locally.
codesign --force --deep --sign - "$APP"

echo "✅ Built $APP"
if [[ "${1:-}" == "--install" ]]; then
  rm -rf "/Applications/NotchPrompter.app"
  cp -R "$APP" /Applications/
  echo "✅ Installed to /Applications/NotchPrompter.app"
fi
echo "Run it with: open \"$APP\""
