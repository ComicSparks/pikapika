#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/lib.sh
write_bundled_version
flutter config --enable-macos-desktop

flutter build macos --release
rm -f build/build.dmg
hdiutil create \
  -volname pikapika \
  -srcfolder build/macos/Build/Products/Release/pikapika.app \
  -ov \
  -format UDZO \
  build/build.dmg
