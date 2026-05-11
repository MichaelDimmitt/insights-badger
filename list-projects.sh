#!/usr/bin/env bash
set -euo pipefail

BACKUP="$HOME/backup"
LIVE="$HOME/.claude/usage-data"

{
  shopt -s nullglob
  for d in "$LIVE/session-meta"; do
    [[ -d "$d" ]] || continue
    for f in "$d"/*.json; do
      p=$(sed -n 's/.*"project_path": *"\([^"]*\)".*/\1/p' "$f" | head -1)
      [[ -z "$p" ]] && p="(unknown)"
      echo "$p"
    done
  done
} | sort | uniq -c | sort -rn
