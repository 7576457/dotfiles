#!/usr/bin/env bash

set -euo pipefail

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/ocr.lock"
flock -n 9 || exit 0

LANGS="eng+rus"

geometry=$(slurp) || exit 0

text=$(grim -g "$geometry" - | tesseract stdin stdout -l "$LANGS" --psm 6 2>/dev/null) || exit 1

[ -n "${text//[[:space:]]/}" ] || exit 0

printf '%s' "$text" | wl-copy 9>&-
