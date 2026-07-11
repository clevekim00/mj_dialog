#!/usr/bin/env bash
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/build/ios_diagnostics"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
REPORT_DIR="${LOG_DIR}/${TIMESTAMP}"
XCODE_LOG="${REPORT_DIR}/xcodebuild.log"
SUMMARY="${REPORT_DIR}/summary.txt"

mkdir -p "$REPORT_DIR"
cd "$PROJECT_ROOT"

{
  echo "Speech Rehab iOS build diagnostics"
  echo "timestamp: ${TIMESTAMP}"
  echo "project: ${PROJECT_ROOT}"
  echo
  echo "== tool versions =="
  flutter --version
  echo
  xcodebuild -version
  echo
  echo "== flutter doctor =="
  flutter doctor -v
  echo
  echo "== workspace schemes =="
  xcodebuild -list -workspace ios/Runner.xcworkspace
} > "$SUMMARY" 2>&1

echo "Writing diagnostics to: $REPORT_DIR"
echo "Building Debug iphoneos with xcodebuild..."

xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  build \
  2>&1 | tee "$XCODE_LOG"

BUILD_STATUS=${PIPESTATUS[0]}
APP_PATH="$(find "${HOME}/Library/Developer/Xcode/DerivedData" \
  -path '*/Build/Products/Debug-iphoneos/Runner.app' \
  -not -path '*/Index.noindex/*' \
  -type d \
  -print 2>/dev/null | head -n 1)"

{
  echo
  echo "== xcodebuild status =="
  echo "$BUILD_STATUS"
  echo
  echo "== latest Runner.app =="
  echo "${APP_PATH:-not found}"
  echo
  if [[ -n "${APP_PATH:-}" && -d "$APP_PATH" ]]; then
    echo "== app signature =="
    codesign -dv --verbose=4 "$APP_PATH" 2>&1 || true
    echo
    echo "== app deep verification =="
    codesign --verify --deep --strict --verbose=4 "$APP_PATH" 2>&1 || true
    echo
    echo "== embedded framework signatures =="
    find "$APP_PATH/Frameworks" -maxdepth 1 -name '*.framework' -type d -print | sort | while read -r framework; do
      echo
      echo "-- ${framework##*/} --"
      codesign -dv --verbose=4 "$framework" 2>&1 || true
      codesign --verify --strict --verbose=2 "$framework" 2>&1 || true
    done
  fi
  echo
  echo "== likely signing/install errors from xcodebuild log =="
  grep -Ei 'codesign|signature|Signing|CodeSign|MIInstaller|ApplicationVerificationFailed|CSSMERR|error:' "$XCODE_LOG" || true
} >> "$SUMMARY"

echo
echo "Diagnostics complete."
echo "Summary: $SUMMARY"
echo "Full build log: $XCODE_LOG"
exit "$BUILD_STATUS"
