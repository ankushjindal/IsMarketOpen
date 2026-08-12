#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/IsMarketOpen.app"
CONTENTS_DIR="$APP_DIR/Contents"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"

export SWIFTPM_MODULECACHE_OVERRIDE="$PROJECT_DIR/.build/module-cache"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/clang-cache"

mkdir -p "$SWIFTPM_MODULECACHE_OVERRIDE" "$CLANG_MODULE_CACHE_PATH"
swift build --package-path "$PROJECT_DIR" -c release --disable-sandbox
BIN_DIR="$(swift build --package-path "$PROJECT_DIR" -c release --show-bin-path --disable-sandbox)"

rm -rf "$APP_DIR" "$ICONSET_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$RESOURCES_DIR/Calendars" "$ICONSET_DIR"

cp "$BIN_DIR/IsMarketOpen" "$CONTENTS_DIR/MacOS/IsMarketOpen"
cp "$PROJECT_DIR/scripts/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$PROJECT_DIR/Calendars/markets.json" "$RESOURCES_DIR/Calendars/markets.json"

swift "$PROJECT_DIR/scripts/GenerateAppIcon.swift" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"

codesign --force --deep --sign - "$APP_DIR"
plutil -lint "$CONTENTS_DIR/Info.plist"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "$APP_DIR"
