#!/usr/bin/env bash
set -euo pipefail

BACKUP="$HOME/backup"
DEST="$HOME/.claude/usage-data"

mkdir -p "$DEST/session-meta" "$DEST/facets"

shopt -s nullglob
for f in "$BACKUP/session-meta"/*.json; do
  mv "$f" "$DEST/session-meta/"
done
for f in "$BACKUP/facets"/*.json; do
  mv "$f" "$DEST/facets/"
done

echo "session-meta restored: $(ls "$DEST/session-meta" | wc -l | tr -d ' ') files"
echo "facets restored:       $(ls "$DEST/facets" | wc -l | tr -d ' ') files"
echo "remaining in backup/session-meta: $(ls "$BACKUP/session-meta" 2>/dev/null | wc -l | tr -d ' ')"
echo "remaining in backup/facets:       $(ls "$BACKUP/facets" 2>/dev/null | wc -l | tr -d ' ')"
