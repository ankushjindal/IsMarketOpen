#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_DIR="$PROJECT_DIR/build/IsMarketOpenPreview.app"
BIN_DIR="$APP_DIR/Contents/MacOS"
mkdir -p "$PROJECT_DIR/build" "$PROJECT_DIR/.build/clang-cache"

swiftc \
  -D ISMARKETOPEN_PREVIEW \
  -module-cache-path "$PROJECT_DIR/.build/clang-cache" \
  -parse-as-library \
  $(find "$PROJECT_DIR/Sources/IsMarketOpen" -name '*.swift' -print) \
  "$PROJECT_DIR/scripts/PreviewMain.swift" \
  -o "$PROJECT_DIR/build/IsMarketOpenPreview"

rm -rf "$APP_DIR"
mkdir -p "$BIN_DIR"
cp "$PROJECT_DIR/build/IsMarketOpenPreview" "$BIN_DIR/IsMarketOpenPreview"
cp "$PROJECT_DIR/scripts/PreviewInfo.plist" "$APP_DIR/Contents/Info.plist"
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
