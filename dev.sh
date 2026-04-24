#!/usr/bin/env bash
# Build Iris in Debug and re-launch the fresh binary.
# Usage: ./dev.sh

set -euo pipefail

cd "$(dirname "$0")"

PROJECT="Iris.xcodeproj"
SCHEME="Iris"
CONFIG="Debug"

echo "› Building $SCHEME ($CONFIG)…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  build \
  -quiet

BUILT_DIR=$(
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -showBuildSettings 2>/dev/null \
  | awk -F ' = ' '/^ *BUILT_PRODUCTS_DIR / {print $2; exit}'
)

APP="$BUILT_DIR/$SCHEME.app"
if [[ ! -d "$APP" ]]; then
  echo "✗ Built app not found at $APP" >&2
  exit 1
fi

echo "› Stopping any running ${SCHEME}…"
if pkill -x "$SCHEME" 2>/dev/null; then
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x "$SCHEME" >/dev/null || break
    sleep 0.3
  done
fi

echo "› Launching $APP"
open -n "$APP"
