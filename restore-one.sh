#!/usr/bin/env bash
set -euo pipefail

# Move ONE parked project directory from ~/backup/projects/ back into
# ~/.claude/projects/ and clear usage-data caches so /insights rebuilds clean.
# Match by substring against the decoded project path (e.g. "scripts" or
# "designer-career-blueprint/next-web").

LIVE_PROJECTS="$HOME/.claude/projects"
LIVE_USAGE="$HOME/.claude/usage-data"
BACKUP_PROJECTS="$HOME/backup/projects"

list_backup() {
  echo "Available in backup:"
  shopt -s nullglob
  for d in "$BACKUP_PROJECTS"/*/; do
    local name count
    name=$(basename "$d")
    count=$(find "$d" -maxdepth 1 -name '*.jsonl' | wc -l | tr -d ' ')
    printf '  %4s sessions  %s\n' "$count" "$name"
  done
}

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-path-substring>"
  echo
  list_backup
  exit 1
fi

query="$1"

if [[ ! -d "$BACKUP_PROJECTS" ]] || [[ -z "$(ls -A "$BACKUP_PROJECTS" 2>/dev/null)" ]]; then
  echo "Nothing in $BACKUP_PROJECTS. Run backup-projects.sh first."
  exit 1
fi

mkdir -p "$LIVE_PROJECTS" "$LIVE_USAGE/session-meta" "$LIVE_USAGE/facets"

shopt -s nullglob
matches=()
for d in "$BACKUP_PROJECTS"/*/; do
  name=$(basename "$d")
  if [[ "$name" == *"$query"* ]]; then
    matches+=("$name")
  fi
done

if [[ ${#matches[@]} -eq 0 ]]; then
  echo "No project matches: $query"
  echo
  list_backup
  exit 1
fi

if [[ ${#matches[@]} -gt 1 ]]; then
  echo "Query '$query' matches multiple projects — narrow it:"
  for m in "${matches[@]}"; do
    echo "  $m"
  done
  exit 1
fi

name="${matches[0]}"
mv "$BACKUP_PROJECTS/$name" "$LIVE_PROJECTS/$name"

rm -f "$LIVE_USAGE/session-meta"/*.json 2>/dev/null || true
rm -f "$LIVE_USAGE/facets"/*.json 2>/dev/null || true

count=$(find "$LIVE_PROJECTS/$name" -maxdepth 1 -name '*.jsonl' | wc -l | tr -d ' ')
echo "Restored: $name  ($count sessions)"
echo "usage-data cleared — run /insights to regenerate."
