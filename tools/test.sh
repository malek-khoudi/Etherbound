#!/usr/bin/env bash
# Run the headless test suites. Works on macOS, Windows (Git Bash) and Linux/WSL.
#
# The --import pass is NOT optional: Godot only registers `class_name` globals
# after an import, so a suite that uses a newly added class fails to parse
# without it. Both agents: run this, do not call Godot directly.
#
# Override detection with:  GODOT="/path/to/godot" ./tools/test.sh
set -uo pipefail

find_godot() {
  [[ -n "${GODOT:-}" ]] && { echo "$GODOT"; return; }

  # PATH first, on every platform.
  for n in godot godot4 Godot; do
    command -v "$n" >/dev/null 2>&1 && { command -v "$n"; return; }
  done

  # macOS
  [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]] && \
    { echo "/Applications/Godot.app/Contents/MacOS/Godot"; return; }

  # Windows via Git Bash. Godot ships as a bare .exe, so it turns up wherever
  # it was unzipped. Check the usual spots, newest version last-wins.
  local found=""
  for d in "/c/Tools/Godot" "/c/Program Files/Godot" "$HOME/Downloads" \
           "$HOME/Desktop" "/c/Users/$USER/Documents"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r hit; do found="$hit"; done < <(
      find "$d" -maxdepth 2 -iname 'Godot*.exe' ! -iname '*console*' 2>/dev/null | sort
    )
    [[ -n "$found" ]] && { echo "$found"; return; }
  done
}

GODOT="$(find_godot)"
if [[ -z "$GODOT" ]]; then
  echo "Godot not found."
  echo "Set it explicitly:  GODOT=/path/to/godot ./tools/test.sh"
  exit 127
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "godot: $GODOT"
"$GODOT" --headless --path game --import >/dev/null 2>&1

fail=0
for t in game/tests/*_test.gd; do
  name="$(basename "$t")"
  "$GODOT" --headless --path game --script "res://tests/$name" 2>&1 \
    | grep -vE '^Godot Engine v|^$|godotengine\.org'
  [[ "${PIPESTATUS[0]}" -ne 0 ]] && fail=1
done

exit "$fail"
