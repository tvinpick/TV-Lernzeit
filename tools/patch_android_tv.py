#!/usr/bin/env python3
"""Adds the Android TV specifics to Godot's Gradle build template (idempotent).

Run after `godot --install-android-build-template` (tools/build_apk.sh does it):
  * <uses-feature android.software.leanback required=false>
  * <uses-feature android.hardware.touchscreen required=false>
  * android:banner="@drawable/tv_banner" (320x180 xhdpi banner for the TV home screen)
Godot itself adds the LEANBACK_LAUNCHER category ("Show In Android TV" preset option).
Usage: python3 tools/patch_android_tv.py lernzeit
"""
import os, re, shutil, sys

proj = sys.argv[1] if len(sys.argv) > 1 else "lernzeit"
build = os.path.join(proj, "android", "build")
manifest = os.path.join(build, "src", "main", "AndroidManifest.xml")
if not os.path.exists(manifest):
    sys.exit(f"{manifest} not found – install the Android build template first")

s = open(manifest, encoding="utf-8").read()
features = (
    '    <uses-feature android:name="android.software.leanback" android:required="false" />\n'
    '    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />\n'
)
if "android.software.leanback" not in s:
    s = s.replace("    <application", features + "\n    <application", 1)
if "android:banner=" not in s:
    s = re.sub(r"(<application\b)", r'\1\n        android:banner="@drawable/tv_banner"', s, count=1)
open(manifest, "w", encoding="utf-8").write(s)

for d in ("drawable-xhdpi", "drawable"):
    dst = os.path.join(build, "res", d)
    os.makedirs(dst, exist_ok=True)
    shutil.copy(os.path.join(proj, "assets", "branding", "tv_banner_320x180.png"), os.path.join(dst, "tv_banner.png"))
print("Android TV manifest patch applied:", manifest)
