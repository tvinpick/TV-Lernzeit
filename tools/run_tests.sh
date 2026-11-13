#!/usr/bin/env bash
# Runs every automated test of Lernzeit and prints a summary.
#   tools/run_tests.sh [OUT_DIR]        (Linux; needs Godot 4.7 as "godot" and xvfb-run)
# Phases: unit tests, main UI walk-through (+ restart check), 4K, achievements/
# letters, full remote run-through of every exercise, layout audit (DE/RU × normal/large).
set -u
cd "$(dirname "$0")/../lernzeit"
OUT="${1:-/tmp/lernzeit_tests}"
rm -rf "$OUT"; mkdir -p "$OUT"
GODOT="${GODOT:-godot}"
run() {  # name, resolution, scene, args...
  local name=$1 res=$2 scene=$3; shift 3
  timeout 900 xvfb-run -a -s "-screen 0 ${res}x24" "$GODOT" --path . --rendering-driver opengl3 \
    --resolution "$res" "$scene" -- "$@" < /dev/null > "$OUT/$name.log" 2>&1
  grep -E "UI TEST|UNIT TESTS|LAYOUT AUDIT" "$OUT/$name.log" | sed "s/^/[$name] /"
  grep -E "  FAIL|ISSUE|SCRIPT ERROR" "$OUT/$name.log" | head -20 | sed "s/^/[$name]   /"
}
"$GODOT" --headless --path . --import > /dev/null 2>&1
run unit 1920x1080 res://tests/UnitTests.tscn --lz-data-dir="$OUT/d_unit"
run main 1920x1080 res://tests/UiTest.tscn --lz-data-dir="$OUT/d_main" --shots="$OUT/shots_main"
run restart 1920x1080 res://tests/UiTest.tscn --lz-data-dir="$OUT/d_main" --phase=restart
run uhd 3840x2160 res://tests/UiTest.tscn --lz-data-dir="$OUT/d_4k" --shots="$OUT/shots_main" --phase=shots4k
run extras 1920x1080 res://tests/UiTest.tscn --lz-data-dir="$OUT/d_x" --shots="$OUT/shots_main" --phase=extras
for e in count10 add10 sub10 count20 add20 sub20 cmp10 zr20 de_letters de_anlaute de_woerter de_case le_silben le_woerter lg_muster lg_formen lg_reihenfolge; do
  run "ex_$e" 1920x1080 res://tests/UiTest.tscn --lz-data-dir="$OUT/d_$e" --shots="$OUT/shots_ex" --phase=exercise --exercise=$e
done
for cfg in "de 0" "de 1" "ru 0" "ru 1"; do
  set -- $cfg
  run "audit_$1$2" 1920x1080 res://tests/LayoutAudit.tscn --lz-data-dir="$OUT/d_a$1$2" --lang=$1 --large=$2 --shots="$OUT/audit_$1$2"
done
echo "-----"
cat "$OUT"/*.log | grep -E "UI TEST|UNIT TESTS" | awk '{s+=$3; f+=$5} END {print "checks:", s, " failures:", f}'
cat "$OUT"/audit_*.log | grep -E "LAYOUT AUDIT" | sed -E 's/.*\]: ([0-9]+) screens, ([0-9]+) focusable.*, ([0-9]+) issues.*/\1 \2 \3/' \
  | awk '{s+=$1; c+=$2; f+=$3} END {print "layout audit screens:", s, " focusable controls:", c, " issues:", f}'
