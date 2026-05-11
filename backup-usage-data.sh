#!/usr/bin/env bash
set -euo pipefail

SRC="$HOME/.claude/usage-data"
DEST="$HOME/backup"

mkdir -p "$DEST/session-meta" "$DEST/facets"

shopt -s nullglob
for f in "$SRC/session-meta"/*.json; do
  mv "$f" "$DEST/session-meta/"
done
for f in "$SRC/facets"/*.json; do
  mv "$f" "$DEST/facets/"
done

echo "session-meta backed up: $(ls "$DEST/session-meta" | wc -l | tr -d ' ') files"
echo "facets backed up:       $(ls "$DEST/facets" | wc -l | tr -d ' ') files"
echo "session-meta remaining in usage-data: $(ls "$SRC/session-meta" 2>/dev/null | wc -l | tr -d ' ')"
echo "facets remaining in usage-data:       $(ls "$SRC/facets" 2>/dev/null | wc -l | tr -d ' ')"
