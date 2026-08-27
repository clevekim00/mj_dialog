#!/usr/bin/env bash
set -euo pipefail

mfa model download dictionary korean_mfa
mfa model download acoustic korean_mfa
mfa model inspect dictionary korean_mfa
mfa model inspect acoustic korean_mfa
mfa model download dictionary english_us_mfa
mfa model download acoustic english_mfa
mfa model inspect dictionary english_us_mfa
mfa model inspect acoustic english_mfa
