#!/usr/bin/env bash
set -euo pipefail

# Scan both ~/.claude/projects/ (live) and ~/backup/projects/ (parked).
# Show decoded project path, session count, and location.

LIVE_PROJECTS="$HOME/.claude/projects"
BACKUP_PROJECTS="$HOME/backup/projects"

scan() {
  local root="$1" label="$2"
  shopt -s nullglob
  for d in "$root"/*/; do
    local name count
    name=$(basename "$d")
    count=$(find "$d" -maxdepth 1 -name '*.jsonl' | wc -l | tr -d ' ')
    printf '  %4s sessions  [%s]  %s\n' "$count" "$label" "$name"
  done
}

echo "Live (~/.claude/projects):"
scan "$LIVE_PROJECTS" "live"
echo
echo "Backup (~/backup/projects):"
scan "$BACKUP_PROJECTS" "backup"
