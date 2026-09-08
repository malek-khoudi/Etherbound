#!/usr/bin/env bash
# Run the headless test suites.
#
# The --import pass is NOT optional: Godot only registers `class_name` globals
# after an import, so a suite that uses a newly added class fails to parse
# without it. Both agents: run this, do not call Godot directly.
set -uo pipefail

GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
  for c in "/Applications/Godot.app/Contents/MacOS/Godot" "$(command -v godot || true)"; do
    [[ -x "$c" ]] && GODOT="$c" && break
  done
fi
[[ -z "$GODOT" ]] && { echo "Godot not found. Set GODOT=/path/to/godot"; exit 127; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

"$GODOT" --headless --path game --import >/dev/null 2>&1

fail=0
for t in game/tests/*_test.gd; do
  name="$(basename "$t")"
  "$GODOT" --headless --path game --script "res://tests/$name" 2>&1 \
    | grep -vE '^Godot Engine v|^$|godotengine\.org'
  status="${PIPESTATUS[0]}"
  [[ "$status" -ne 0 ]] && fail=1
done

exit "$fail"
