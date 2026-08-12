#!/bin/zsh

set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
OUTPUT_PATH="${1:-$PROJECT_DIR/Calendars/markets.json}"
TASK_TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TASK_TEMP_DIR"' EXIT

swiftc \
  "$PROJECT_DIR/Sources/IsMarketOpen/Models/MarketModels.swift" \
  "$PROJECT_DIR/Sources/IsMarketOpen/Models/CalendarManifest.swift" \
  "$PROJECT_DIR/Sources/IsMarketOpen/Calendar/BundledCalendar.swift" \
  "$PROJECT_DIR/scripts/ExportBundledCalendar.swift" \
  -o "$TASK_TEMP_DIR/export-calendar"

"$TASK_TEMP_DIR/export-calendar" "$OUTPUT_PATH"
echo "Updated $OUTPUT_PATH"
