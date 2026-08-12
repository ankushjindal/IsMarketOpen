#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
export SWIFTPM_MODULECACHE_OVERRIDE="$PROJECT_DIR/.build/module-cache"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/clang-cache"
mkdir -p "$SWIFTPM_MODULECACHE_OVERRIDE" "$CLANG_MODULE_CACHE_PATH"
swift test --package-path "$PROJECT_DIR" --disable-sandbox
