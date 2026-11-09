#!/usr/bin/env bash
# 构建未签名 IPA。Rust 由 flutter_rust_bridge 的 cargokit 在编译 iOS 时产出。
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/lib.sh
write_bundled_version

if /usr/libexec/PlistBuddy -c 'Print :application-identifier' ios/Runner/Info.plist >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c 'Set :application-identifier opensource.pikapika' ios/Runner/Info.plist
else
  /usr/libexec/PlistBuddy -c 'Add :application-identifier string opensource.pikapika' ios/Runner/Info.plist
fi

export CODE_SIGNING_REQUIRED=NO
export CODE_SIGNING_ALLOWED=NO
flutter build ios --release --no-codesign

rm -rf build/Payload build/nosign.ipa
mkdir -p build/Payload
cp -R build/ios/iphoneos/Runner.app build/Payload/
(
  cd build
  zip -9 -r nosign.ipa Payload
)
