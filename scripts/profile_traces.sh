#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <output_dir> [app_path]"
  echo "Example: $0 .context/perf/$(date +%Y%m%d-%H%M%S) ~/Library/Developer/Xcode/DerivedData/.../DailyOS.app"
  exit 1
fi

OUTPUT_DIR="$1"
APP_PATH="${2:-}"
DEVICE_ID="${DEVICE_ID:-3A14B487-2638-424C-8109-53AD784C334D}"
PROCESS_NAME="${PROCESS_NAME:-DailyOS}"
ATTACH_DURATION="${ATTACH_DURATION:-8s}"
LAUNCH_DURATION="${LAUNCH_DURATION:-10s}"

mkdir -p "$OUTPUT_DIR"

echo "Profiling output dir: $OUTPUT_DIR"
echo "Device: $DEVICE_ID"
echo "Process: $PROCESS_NAME"

record_attach() {
  local template="$1"
  local file_name="$2"

  echo "Recording '$template' -> $OUTPUT_DIR/$file_name.trace"
  if [[ -n "$APP_PATH" ]]; then
    if ! xcrun xctrace record \
      --template "$template" \
      --device "$DEVICE_ID" \
      --time-limit "$ATTACH_DURATION" \
      --output "$OUTPUT_DIR/$file_name.trace" \
      --launch -- "$APP_PATH" \
      --no-prompt; then
      echo "Warning: template '$template' is unavailable on the current platform. Skipping."
    fi
  else
    if ! xcrun xctrace record \
      --template "$template" \
      --device "$DEVICE_ID" \
      --attach "$PROCESS_NAME" \
      --time-limit "$ATTACH_DURATION" \
      --output "$OUTPUT_DIR/$file_name.trace" \
      --no-prompt; then
      echo "Warning: template '$template' is unavailable on the current platform. Skipping."
    fi
  fi
}

if [[ -n "$APP_PATH" ]]; then
  echo "Recording 'App Launch' -> $OUTPUT_DIR/app-launch.trace"
  if ! xcrun xctrace record \
    --template "App Launch" \
    --device "$DEVICE_ID" \
    --time-limit "$LAUNCH_DURATION" \
    --output "$OUTPUT_DIR/app-launch.trace" \
    --launch -- "$APP_PATH" \
    --no-prompt; then
    echo "Warning: App Launch template failed. Continuing with attach templates."
  fi
else
  echo "Skipping App Launch capture (no app path provided)."
fi

record_attach "Time Profiler" "time-profiler"
record_attach "SwiftUI" "swiftui"
record_attach "Animation Hitches" "animation-hitches"
record_attach "Data Persistence" "data-persistence"

echo "Done. Trace artifacts saved in $OUTPUT_DIR"
