#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
KEY_PROPERTIES="${PROJECT_ROOT}/android/key.properties"

cd "$PROJECT_ROOT"

if [[ ! -f "$KEY_PROPERTIES" ]]; then
  cat >&2 <<'MESSAGE'
Missing android/key.properties.

Create an Android upload keystore, then copy:
  android/key.properties.example -> android/key.properties

Fill in storePassword, keyPassword, keyAlias, and storeFile.
The real key.properties and *.jks files are ignored by git.
MESSAGE
  exit 66
fi

flutter build appbundle --release

cat <<'MESSAGE'

Android release bundle is ready:
  build/app/outputs/bundle/release/app-release.aab
MESSAGE
