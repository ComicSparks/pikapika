#!/usr/bin/env bash
# 使用仓库 secret 里的 keystore 重签 split APK。未配置时保留 Flutter 的 debug 签名。
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${KEY_FILE_BASE64:-}" || -z "${KEY_PASSWORD:-}" ]]; then
  echo "KEY_FILE_BASE64 或 KEY_PASSWORD 未设置，跳过重签"
  exit 0
fi

if [[ -n "${ANDROID_HOME:-}" ]]; then
  sdk="$ANDROID_HOME"
elif [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  sdk="$ANDROID_SDK_ROOT"
else
  echo "找不到 Android SDK" >&2
  exit 1
fi

apksigner="$(find "$sdk/build-tools" -type f -name apksigner | sort | tail -n 1)"
if [[ -z "$apksigner" ]]; then
  echo "找不到 apksigner" >&2
  exit 1
fi

printf '%s' "$KEY_FILE_BASE64" | base64 -d >key.jks
trap 'rm -f key.jks' EXIT

shopt -s nullglob
apks=(build/app/outputs/flutter-apk/*-release.apk)
if [[ ${#apks[@]} -eq 0 ]]; then
  echo "没有可签名的 APK" >&2
  exit 1
fi
for apk in "${apks[@]}"; do
  "$apksigner" sign --ks key.jks --ks-pass "pass:${KEY_PASSWORD}" "$apk"
  echo "signed $apk"
done
