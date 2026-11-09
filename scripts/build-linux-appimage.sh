#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/lib.sh
write_bundled_version
flutter config --enable-linux-desktop

if [[ ! -f linux/pikapika.png ]]; then
  base64 -d >linux/pikapika.png <<'EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==
EOF
fi

flutter build linux --release

rm -rf build/AppDir
mkdir -p build/AppDir/usr/bin
cp -a build/linux/x64/release/bundle/. build/AppDir/usr/bin/
cp linux/pikapika.desktop build/AppDir/pikapika.desktop
cp linux/pikapika.png build/AppDir/pikapika.png
cat >build/AppDir/AppRun <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/pikapika" "$@"
EOF
chmod +x build/AppDir/AppRun

if [[ ! -x "${GITHUB_WORKSPACE:-}/bin/appimagetool" && ! -x /usr/local/bin/appimagetool ]]; then
  mkdir -p "${HOME}/bin"
  curl -L -o "${HOME}/bin/appimagetool" \
    https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x "${HOME}/bin/appimagetool"
  export PATH="${HOME}/bin:${PATH}"
fi
export APPIMAGE_EXTRACT_AND_RUN=1
appimagetool build/AppDir build/build.AppImage
chmod +x build/build.AppImage
