#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Targie"
EXECUTABLE_NAME="SimilarVideoFinder"
BUNDLE_ID="local.aaronyu.SimilarVideoFinder"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"

cd "$ROOT_DIR"
export HOME="$ROOT_DIR/.build/home"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/swiftpm-module-cache"
export COPYFILE_DISABLE=1
swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$EXECUTABLE_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BUILD_BINARY" "$CONTENTS/MacOS/$EXECUTABLE_NAME"
chmod +x "$CONTENTS/MacOS/$EXECUTABLE_NAME"

printf '%s\n' \
  '<?xml version="1.0" encoding="UTF-8"?>' \
  '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
  '<plist version="1.0"><dict>' \
  '<key>CFBundleExecutable</key><string>SimilarVideoFinder</string>' \
  '<key>CFBundleIdentifier</key><string>local.aaronyu.SimilarVideoFinder</string>' \
  '<key>CFBundleName</key><string>Targie</string>' \
  '<key>CFBundleDisplayName</key><string>Targie</string>' \
  '<key>CFBundlePackageType</key><string>APPL</string>' \
  '<key>LSMinimumSystemVersion</key><string>14.0</string>' \
  '<key>NSPrincipalClass</key><string>NSApplication</string>' \
  '</dict></plist>' > "$CONTENTS/Info.plist"

xattr -cr "$APP_BUNDLE"
codesign --force --sign - --identifier "$BUNDLE_ID" "$CONTENTS/MacOS/$EXECUTABLE_NAME"
plutil -lint "$CONTENTS/Info.plist" >/dev/null
codesign --verify --strict "$CONTENTS/MacOS/$EXECUTABLE_NAME"
echo "$APP_BUNDLE"
