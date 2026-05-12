#!/usr/bin/env bash
set -euo pipefail

# Move every project transcript directory out of ~/.claude/projects/ to
# ~/backup/projects/, and clear the derived ~/.claude/usage-data/ caches.
# After this, /insights has no sessions to analyze.

LIVE_PROJECTS="$HOME/.claude/projects"
LIVE_USAGE="$HOME/.claude/usage-data"
BACKUP_PROJECTS="$HOME/backup/projects"

mkdir -p "$BACKUP_PROJECTS"

shopt -s nullglob
moved=0
for d in "$LIVE_PROJECTS"/*/; do
  name=$(basename "$d")
  mv "$d" "$BACKUP_PROJECTS/$name"
  moved=$((moved + 1))
done

rm -f "$LIVE_USAGE/session-meta"/*.json 2>/dev/null || true
rm -f "$LIVE_USAGE/facets"/*.json 2>/dev/null || true

echo "projects moved to backup: $moved"
echo "projects remaining live:  $(find "$LIVE_PROJECTS" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
echo "session-meta cleared:     $(ls "$LIVE_USAGE/session-meta" 2>/dev/null | wc -l | tr -d ' ') files remain"
echo "facets cleared:           $(ls "$LIVE_USAGE/facets" 2>/dev/null | wc -l | tr -d ' ') files remain"
