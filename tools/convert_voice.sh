#!/usr/bin/env bash
# Converts the WAV voice recordings (Lernzeit_DE_Nele_198_WAV.zip, unpacked) to OGG Vorbis
# for the app:   tools/convert_voice.sh <folder with *.wav>
# Needs ffmpeg. Existing files in lernzeit/assets/voice/de are overwritten.
set -eu
SRC="$1"
DST="$(dirname "$0")/../lernzeit/assets/voice/de"
mkdir -p "$DST"
for f in "$SRC"/*.wav; do
  ffmpeg -loglevel error -y -i "$f" -ac 1 -ar 44100 -c:a libvorbis -q:a 4 "$DST/$(basename "$f" .wav).ogg"
done
ls "$DST"/*.ogg | wc -l
