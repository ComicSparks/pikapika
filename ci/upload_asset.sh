#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/lib.sh

target="${TARGET:?TARGET is required}"
tag="$(version_tag)"
mkdir -p build/release-assets

copy_named() {
  local src="$1"
  local name="$2"
  if [[ ! -f "$src" ]]; then
    echo "missing build output: $src" >&2
    exit 1
  fi
  if [[ "$(wc -c <"$src" | tr -d ' ')" -le 166 ]]; then
    echo "build output looks empty: $src" >&2
    exit 1
  fi
  cp "$src" "build/release-assets/$name"
}

case "$target" in
  macos)
    copy_named build/build.dmg "$(asset_name macos)"
    ;;
  ios)
    copy_named build/nosign.ipa "$(asset_name ios)"
    ;;
  windows)
    copy_named build/build.zip "$(asset_name windows)"
    ;;
  linux)
    copy_named build/build.AppImage "$(asset_name linux)"
    ;;
  android)
    copy_named build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "$(asset_name android-arm32)"
    copy_named build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$(asset_name android-arm64)"
    copy_named build/app/outputs/flutter-apk/app-x86_64-release.apk "$(asset_name android-x86_64)"
    ;;
  *)
    echo "unknown target: $target" >&2
    exit 1
    ;;
esac

if [[ "${STAGE_ONLY:-}" == "1" ]]; then
  echo "staged assets in build/release-assets"
  exit 0
fi

gh release upload "$tag" build/release-assets/* --clobber
