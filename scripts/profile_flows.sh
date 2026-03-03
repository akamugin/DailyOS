#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <output_dir> [app_path]"
  echo "Example: $0 .context/perf/flows-$(date +%Y%m%d-%H%M%S) ~/Library/Developer/Xcode/DerivedData/.../DailyOS.app"
  exit 1
fi

OUTPUT_DIR="$1"
APP_PATH="${2:-}"
DEVICE_ID="${DEVICE_ID:-3A14B487-2638-424C-8109-53AD784C334D}"
PROCESS_NAME="${PROCESS_NAME:-DailyOS}"
TEMPLATE="${TEMPLATE:-Time Profiler}"
DURATION="${DURATION:-8s}"

mkdir -p "$OUTPUT_DIR"

flows=(
  "launch-steady-state"
  "add-block"
  "edit-block"
  "toggle-done"
  "delete-block"
  "swipe-day"
)

for flow in "${flows[@]}"; do
  echo ""
  echo "Prepare simulator for flow: $flow"
  echo "Press Enter to start recording $flow ..."
  read -r

  if [[ -n "$APP_PATH" ]]; then
    xcrun xctrace record \
      --template "$TEMPLATE" \
      --device "$DEVICE_ID" \
      --time-limit "$DURATION" \
      --output "$OUTPUT_DIR/$flow.trace" \
      --launch -- "$APP_PATH" \
      --no-prompt
  else
    xcrun xctrace record \
      --template "$TEMPLATE" \
      --device "$DEVICE_ID" \
      --attach "$PROCESS_NAME" \
      --time-limit "$DURATION" \
      --output "$OUTPUT_DIR/$flow.trace" \
      --no-prompt
  fi

done

echo "Done. Flow traces saved in $OUTPUT_DIR"
