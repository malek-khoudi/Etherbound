#!/usr/bin/env bash
# Run the headless test suites. Works on macOS, Windows (Git Bash) and Linux/WSL.
#
# The --import pass is NOT optional: Godot only registers `class_name` globals
# after an import, so a suite that uses a newly added class fails to parse
# without it. Both agents: run this, do not call Godot directly.
#
# Override detection with:  GODOT="/path/to/godot" ./tools/test.sh
set -uo pipefail

# Codex and other non-interactive Windows callers can launch Git Bash without
# its usual profile, leaving core utilities such as dirname, find and grep off
# PATH. These locations are harmless on Unix and restore Git's tools on MSYS.
[[ -d "/usr/bin" ]] && PATH="/usr/bin:$PATH"
[[ -d "/mingw64/bin" ]] && PATH="/mingw64/bin:$PATH"
export PATH

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
           "$HOME/Desktop" "$HOME/Documents"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r hit; do found="$hit"; done < <(
      find "$d" -maxdepth 4 -iname 'Godot*.exe' ! -iname '*console*' 2>/dev/null | sort
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
version="$("$GODOT" --version 2>/dev/null)"
if [[ "$version" == *".mono."* ]]; then
  echo "Godot Mono/.NET found ($version), but Etherbound requires the standard GDScript build."
  exit 126
fi
echo "version: $version"

# Keep Godot's logs in a writable temporary file. Sandboxed agents may not be
# able to write the default user://logs location even though the project is writable.
log_file="$(mktemp -t etherbound-godot.XXXXXX.log)"
trap 'rm -f "$log_file"' EXIT

if ! "$GODOT" --headless --path game --log-file "$log_file" --import >/dev/null 2>&1; then
  echo "Godot import failed."
  sed -n '1,160p' "$log_file"
  exit 1
fi

fail=0
for t in game/tests/*_test.gd; do
  name="$(basename "$t")"
  "$GODOT" --headless --path game --log-file "$log_file" --script "res://tests/$name" 2>&1 \
    | grep -vE '^Godot Engine v|^$|godotengine\.org'
  [[ "${PIPESTATUS[0]}" -ne 0 ]] && fail=1
done

exit "$fail"
