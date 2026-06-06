#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  scripts/build_and_run.sh <platform> [--device <device-id>] [--profile|--release] [-- <flutter run args>]

Platforms:
  macos | osx       Build macOS app, then run on macOS
  ios               Build iOS simulator app, then run on iOS simulator
  android           Build Android APK, then run on Android
  web | chrome      Build web app, then run in Chrome
  linux             Build Linux app, then run on Linux
  windows           Build Windows app, then run on Windows

Examples:
  scripts/build_and_run.sh macos
  scripts/build_and_run.sh ios --device 97B83775-385E-46BC-958B-3F8AA5435B9A
  scripts/build_and_run.sh web -- --web-port 8080
  scripts/build_and_run.sh android --release
USAGE
}

if [[ $# -lt 1 || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

PLATFORM="$1"
shift

DEVICE=""
BUILD_MODE="debug"
RUN_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device|-d)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 64
      fi
      DEVICE="$2"
      shift 2
      ;;
    --profile)
      BUILD_MODE="profile"
      shift
      ;;
    --release)
      BUILD_MODE="release"
      shift
      ;;
    --debug)
      BUILD_MODE="debug"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      RUN_ARGS+=("$@")
      break
      ;;
    *)
      RUN_ARGS+=("$1")
      shift
      ;;
  esac
done

case "$PLATFORM" in
  osx)
    PLATFORM="macos"
    ;;
  chrome)
    PLATFORM="web"
    ;;
esac

mode_flag() {
  case "$BUILD_MODE" in
    debug)
      echo "--debug"
      ;;
    profile)
      echo "--profile"
      ;;
    release)
      echo "--release"
      ;;
  esac
}

default_device_for_platform() {
  case "$PLATFORM" in
    macos)
      echo "macos"
      ;;
    ios)
      echo "ios"
      ;;
    android)
      echo "android"
      ;;
    web)
      echo "chrome"
      ;;
    linux)
      echo "linux"
      ;;
    windows)
      echo "windows"
      ;;
    *)
      echo ""
      ;;
  esac
}

build_platform() {
  local flag
  flag="$(mode_flag)"

  case "$PLATFORM" in
    macos)
      flutter build macos "$flag"
      ;;
    ios)
      if [[ "$BUILD_MODE" == "release" ]]; then
        flutter build ios "$flag"
      else
        flutter build ios --simulator "$flag"
      fi
      ;;
    android)
      if [[ "$BUILD_MODE" == "release" ]]; then
        flutter build apk --release
      elif [[ "$BUILD_MODE" == "profile" ]]; then
        flutter build apk --profile
      else
        flutter build apk --debug
      fi
      ;;
    web)
      if [[ "$BUILD_MODE" == "debug" ]]; then
        flutter build web
      else
        flutter build web "$flag"
      fi
      ;;
    linux)
      flutter build linux "$flag"
      ;;
    windows)
      flutter build windows "$flag"
      ;;
    *)
      echo "Unsupported platform: $PLATFORM" >&2
      usage
      exit 64
      ;;
  esac
}

run_platform() {
  local device="${DEVICE:-$(default_device_for_platform)}"
  if [[ -z "$device" ]]; then
    echo "Could not infer a Flutter device for platform: $PLATFORM" >&2
    exit 64
  fi

  flutter run -d "$device" "$(mode_flag)" "${RUN_ARGS[@]}"
}

cd "$PROJECT_ROOT"

echo "==> Building $PLATFORM ($BUILD_MODE)"
build_platform

echo "==> Running $PLATFORM"
run_platform
