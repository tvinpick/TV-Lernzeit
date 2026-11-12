#!/usr/bin/env bash
# Builds build/Lernzeit_v0_1.apk from the Godot project (Linux/macOS, Godot 4.7.x).
# Requirements: Godot 4.7.2 editor + export templates, Android SDK (platform 36,
# build-tools 36.1.0), JDK 17+, internet access for Gradle on the first build.
#
# Signing: export GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD
# (see README_RU.md). Without them a debug-signed APK is built instead.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
OUT="build/Lernzeit_v0_1.apk"
mkdir -p build

# 1) prepared assets already live in lernzeit/assets (tools/prepare_assets.py regenerates them)
# 2) import resources
"$GODOT" --headless --path lernzeit --import >/dev/null 2>&1 || true
# 3) Gradle build template (only if missing) + Android TV patch
if [ ! -f lernzeit/android/build/src/main/AndroidManifest.xml ]; then
  "$GODOT" --headless --path lernzeit --install-android-build-template --quit || true
  # some Godot versions only install the template together with an export:
  [ -f lernzeit/android/build/src/main/AndroidManifest.xml ] || \
    "$GODOT" --headless --path lernzeit --install-android-build-template --export-debug "Android TV" "../build/_bootstrap.apk" || true
  rm -f build/_bootstrap.apk
fi
python3 tools/patch_android_tv.py lernzeit
# 4) export
if [ -n "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ]; then
  "$GODOT" --headless --path lernzeit --export-release "Android TV" "../$OUT"
else
  echo "No release keystore configured → debug build"
  "$GODOT" --headless --path lernzeit --export-debug "Android TV" "../$OUT"
fi
ls -lh "$OUT"
