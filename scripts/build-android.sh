#!/usr/bin/env bash
# 一次打出 armeabi-v7a、arm64-v8a、x86_64 三个 APK。
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/lib.sh
write_bundled_version

flutter build apk --release --split-per-abi
