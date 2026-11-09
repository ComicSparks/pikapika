#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/lib.sh
write_bundled_version
flutter config --enable-windows-desktop

flutter build windows --release
rm -f build/build.zip
root="$(pwd -W 2>/dev/null || pwd)"
powershell.exe -NoProfile -Command "Compress-Archive -Path '${root}\\build\\windows\\x64\\runner\\Release\\*' -DestinationPath '${root}\\build\\build.zip' -Force"
