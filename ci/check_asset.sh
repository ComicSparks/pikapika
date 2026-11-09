#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/lib.sh

target="${TARGET:?TARGET is required}"
tag="$(version_tag)"
if ! gh release view "$tag" >/dev/null 2>&1; then
  echo "release $tag was not found" >&2
  exit 1
fi

missing=0
while IFS= read -r item; do
  name="$(asset_name "$item")"
  if gh release view "$tag" --json assets --jq '.assets[].name' | grep -qx "$name"; then
    echo "asset exists: $name"
  else
    echo "asset missing: $name"
    missing=1
  fi
done < <(targets_for "$target")

if [[ "$missing" == 0 ]]; then
  echo "skip_build=true" >>"${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
else
  echo "skip_build=false" >>"$GITHUB_OUTPUT"
fi
