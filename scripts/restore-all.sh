#!/usr/bin/env bash
set -euo pipefail

# Move every parked project from ~/backup/projects/ back into ~/.claude/projects/
# and clear usage-data so /insights rebuilds across the full set.

LIVE_PROJECTS="$HOME/.claude/projects"
LIVE_USAGE="$HOME/.claude/usage-data"
BACKUP_PROJECTS="$HOME/backup/projects"

mkdir -p "$LIVE_PROJECTS" "$LIVE_USAGE/session-meta" "$LIVE_USAGE/facets"

shopt -s nullglob
restored=0
for d in "$BACKUP_PROJECTS"/*/; do
  name=$(basename "$d")
  mv "$d" "$LIVE_PROJECTS/$name"
  restored=$((restored + 1))
done

rm -f "$LIVE_USAGE/session-meta"/*.json 2>/dev/null || true
rm -f "$LIVE_USAGE/facets"/*.json 2>/dev/null || true

echo "projects restored:        $restored"
echo "projects remaining backup:$(find "$BACKUP_PROJECTS" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
echo "usage-data cleared — run /insights to regenerate."
