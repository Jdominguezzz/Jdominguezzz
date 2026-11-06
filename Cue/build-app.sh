#!/usr/bin/env bash
# Builds Cue.app into ./build and (with --install) copies it to /Applications.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

APP="build/Cue.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Cue" "$APP/Contents/MacOS/Cue"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# App icon: turn the 1024px PNG into an .icns with Apple's own tools.
ICONSET="build/AppIcon.iconset"
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z $size $size Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z $double $double Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

# Ad-hoc sign so macOS will launch it locally.
codesign --force --deep --sign - "$APP"

echo "✅ Built $APP"
if [[ "${1:-}" == "--install" ]]; then
  rm -rf "/Applications/Cue.app"
  cp -R "$APP" /Applications/
  touch /Applications/Cue.app   # refresh the icon in Finder
  echo "✅ Installed to /Applications/Cue.app"
fi
echo "Run it with: open /Applications/Cue.app"
