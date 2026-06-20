#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Default physical iOS device used during local testing.
# Override with:
#   IOS_DEVICE_ID=<device-id> scripts/run_ios_release_device.sh
# or:
#   scripts/run_ios_release_device.sh --device <device-id>
DEFAULT_IOS_DEVICE_ID="00008027-000849220A31002E"

DEVICE_ID="${IOS_DEVICE_ID:-$DEFAULT_IOS_DEVICE_ID}"
NO_RESIDENT=true
EXTRA_ARGS=()

usage() {
  cat <<'USAGE'
Usage:
  scripts/run_ios_release_device.sh [--device <device-id>] [--resident] [-- <flutter run args>]

What this wraps:
  flutter run --release -d <device-id> --no-resident

Why:
  iOS debug builds launched from the home screen can stop at Flutter's debug-mode
  launch warning. This script always uses a release build for physical-device
  standalone testing.

Examples:
  scripts/run_ios_release_device.sh
  scripts/run_ios_release_device.sh --device 00008027-000849220A31002E
  IOS_DEVICE_ID=00008027-000849220A31002E scripts/run_ios_release_device.sh
  scripts/run_ios_release_device.sh -- --dart-define=KEY=value
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device|-d)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 64
      fi
      DEVICE_ID="$2"
      shift 2
      ;;
    --resident)
      NO_RESIDENT=false
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      EXTRA_ARGS+=("$@")
      break
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

cd "$PROJECT_ROOT"

echo "==> Running iOS release build on device: $DEVICE_ID"
echo "==> Mode: release"
if [[ "$NO_RESIDENT" == true ]]; then
  echo "==> Resident session: disabled (--no-resident)"
else
  echo "==> Resident session: enabled"
fi

RUN_CMD=(flutter run --release -d "$DEVICE_ID")
if [[ "$NO_RESIDENT" == true ]]; then
  RUN_CMD+=(--no-resident)
fi
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  RUN_CMD+=("${EXTRA_ARGS[@]}")
fi

printf '==> Command:'
printf ' %q' "${RUN_CMD[@]}"
printf '\n'

"${RUN_CMD[@]}"
