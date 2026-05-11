#!/usr/bin/env bash
set -euo pipefail

BACKUP="$HOME/backup"
DEST="$HOME/.claude/usage-data"

project_of() {
  sed -n 's/.*"project_path": *"\([^"]*\)".*/\1/p' "$1" | head -1
}

list_grouped() {
  echo "Available in backup (grouped by project):"
  shopt -s nullglob
  declare -A by_project
  for f in "$BACKUP/session-meta"/*.json; do
    id=$(basename "$f" .json)
    p=$(project_of "$f")
    [[ -z "$p" ]] && p="(unknown)"
    by_project[$p]+="    $id"$'\n'
  done
  for p in "${!by_project[@]}"; do
    echo "  $p"
    printf '%s' "${by_project[$p]}"
  done
}

restore_pair() {
  local id="$1"
  local meta="$BACKUP/session-meta/$id.json"
  local facet="$BACKUP/facets/$id.json"
  [[ -f "$meta" ]] || { echo "missing meta: $id"; return 1; }
  mv "$meta" "$DEST/session-meta/"
  if [[ -f "$facet" ]]; then
    mv "$facet" "$DEST/facets/"
  else
    echo "  (no facet for $id)"
  fi
  echo "  restored $id"
}

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <session-id-prefix | project-path-substring>"
  echo
  list_grouped
  exit 1
fi

query="$1"
mkdir -p "$DEST/session-meta" "$DEST/facets"

shopt -s nullglob

id_matches=("$BACKUP/session-meta/$query"*.json)
if [[ ${#id_matches[@]} -eq 1 ]]; then
  restore_pair "$(basename "${id_matches[0]}" .json)"
  exit 0
fi
if [[ ${#id_matches[@]} -gt 1 ]]; then
  echo "Session-id prefix '$query' is ambiguous:"
  for m in "${id_matches[@]}"; do echo "  $(basename "$m" .json)"; done
  exit 1
fi

project_matches=()
for f in "$BACKUP/session-meta"/*.json; do
  p=$(project_of "$f")
  if [[ "$p" == *"$query"* ]]; then
    project_matches+=("$(basename "$f" .json)")
  fi
done

if [[ ${#project_matches[@]} -eq 0 ]]; then
  echo "No session-id prefix or project path matches: $query"
  echo
  list_grouped
  exit 1
fi

distinct_projects=$(
  for id in "${project_matches[@]}"; do
    project_of "$BACKUP/session-meta/$id.json"
  done | sort -u
)
project_count=$(echo "$distinct_projects" | wc -l | tr -d ' ')
if [[ "$project_count" -gt 1 ]]; then
  echo "Query '$query' matches multiple projects — narrow it:"
  echo "$distinct_projects" | sed 's/^/  /'
  exit 1
fi

echo "Restoring ${#project_matches[@]} session(s) for: $distinct_projects"
for id in "${project_matches[@]}"; do
  restore_pair "$id"
done
