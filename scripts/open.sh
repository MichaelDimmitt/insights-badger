#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <file-or-glob> [more files...]" >&2
  echo "Example: $0 'results/*.html'" >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin) opener="open" ;;
  Linux)
    if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
      opener="wslview"
    else
      opener="xdg-open"
    fi
    ;;
  CYGWIN*|MINGW*|MSYS*) opener="start" ;;
  *)
    echo "Unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac

if ! command -v "$opener" >/dev/null 2>&1; then
  echo "Opener '$opener' not found on this system" >&2
  exit 1
fi

shopt -s nullglob

files=()
for arg in "$@"; do
  matches=( $arg )
  if [ "${#matches[@]}" -eq 0 ]; then
    if [ -e "$arg" ]; then
      files+=( "$arg" )
    else
      echo "No match: $arg" >&2
    fi
  else
    files+=( "${matches[@]}" )
  fi
done

if [ "${#files[@]}" -eq 0 ]; then
  echo "Nothing to open." >&2
  exit 1
fi

for f in "${files[@]}"; do
  "$opener" "$f"
done
