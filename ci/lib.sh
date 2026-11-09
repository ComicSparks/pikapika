#!/usr/bin/env bash
# 从 pubspec 读取版本，并按原来的附件命名规则生成文件名。

version_name() {
  awk '/^version:/ { print $2; exit }' pubspec.yaml | cut -d+ -f1
}

version_tag() {
  local name
  name="$(version_name)"
  if [[ "$name" == v* ]]; then
    printf '%s\n' "$name"
  else
    printf 'v%s\n' "$name"
  fi
}

release_notes_file() {
  if [[ -f ci/version.info.txt ]]; then
    printf '%s\n' ci/version.info.txt
  else
    local tmp
    tmp="$(mktemp)"
    version_tag >"$tmp"
    printf '%s\n' "$tmp"
  fi
}

write_bundled_version() {
  mkdir -p lib/assets
  version_tag >lib/assets/version.txt
}

asset_name() {
  local target="$1"
  local tag flutter branch name
  tag="$(version_tag)"
  flutter="${FLUTTER_VERSION:?FLUTTER_VERSION is required}"
  branch="${BRANCH:-${GITHUB_REF_NAME:-master}}"
  case "$target" in
    macos) name="pikapika-${tag}-macos-arm64-flutter_${flutter}.dmg" ;;
    ios) name="pikapika-${tag}-ios_nosign-flutter_${flutter}.ipa" ;;
    windows) name="pikapika-${tag}-windows-x86_64-flutter_${flutter}.zip" ;;
    linux) name="pikapika-${tag}-linux-x86_64-flutter_${flutter}.AppImage" ;;
    android-arm32) name="pikapika-${tag}-android-arm32-flutter_${flutter}.apk" ;;
    android-arm64) name="pikapika-${tag}-android-arm64-flutter_${flutter}.apk" ;;
    android-x86_64) name="pikapika-${tag}-android-x86_64-flutter_${flutter}.apk" ;;
    *)
      echo "unknown target: $target" >&2
      return 1
      ;;
  esac
  if [[ "$branch" != "master" && "$branch" != "main" ]]; then
    name="${branch}-${name}"
  fi
  printf '%s\n' "$name"
}

targets_for() {
  case "$1" in
    android) printf '%s\n' android-arm32 android-arm64 android-x86_64 ;;
    *) printf '%s\n' "$1" ;;
  esac
}
