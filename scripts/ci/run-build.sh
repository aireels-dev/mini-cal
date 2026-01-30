#!/bin/bash

set -euo pipefail

PROJECT="MiniCal.xcodeproj"
SCHEME="MiniCal"
CONFIGURATION="${CONFIGURATION:-Debug}"
RESULT_ROOT="${RESULT_ROOT:-/tmp/xcresults/minical}"
RESULT_BUNDLE="${RESULT_BUNDLE:-${RESULT_ROOT}/MiniCal-build.xcresult}"
LOG_PATH="${LOG_PATH:-${RESULT_ROOT}/MiniCal-build.log}"

mkdir -p "$RESULT_ROOT"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -resultBundlePath "$RESULT_BUNDLE" \
  build | tee "$LOG_PATH"
