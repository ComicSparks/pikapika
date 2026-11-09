#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/lib.sh

tag="$(version_tag)"
notes="$(release_notes_file)"
if gh release view "$tag" >/dev/null 2>&1; then
  echo "release $tag already exists"
else
  gh release create "$tag" \
    --target "${GITHUB_REF_NAME}" \
    --title "$tag" \
    --notes-file "$notes"
  echo "created release $tag"
fi
