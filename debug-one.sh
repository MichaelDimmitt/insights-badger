#!/usr/bin/env bash
set -euo pipefail

# Debug variant of restore-one.sh + insights-per-project.sh for a single project.
# Restores one parked project, clears usage-data, then runs the VERBOSE expect
# script so you can watch the TUI live and diagnose why report.html isn't
# updating. The project is left LIVE afterwards — re-park with backup-projects.sh
# when done.

LIVE_PROJECTS="$HOME/.claude/projects"
LIVE_USAGE="$HOME/.claude/usage-data"
BACKUP_PROJECTS="$HOME/backup/projects"
REPORTS="$HOME/insights-badger/results"
REPORT_SRC="$LIVE_USAGE/report.html"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-substring>"
  echo
  echo "Available in backup:"
  shopt -s nullglob
  for d in "$BACKUP_PROJECTS"/*/; do
    echo "  $(basename "$d")"
  done
  exit 1
fi

query="$1"

mkdir -p "$LIVE_PROJECTS" "$LIVE_USAGE/session-meta" "$LIVE_USAGE/facets" "$REPORTS"

shopt -s nullglob
matches=()
for d in "$BACKUP_PROJECTS"/*/; do
  name=$(basename "$d")
  if [[ "$name" == *"$query"* ]]; then
    matches+=("$name")
  fi
done

if [[ ${#matches[@]} -eq 0 ]]; then
  echo "No backup project matches: $query"
  exit 1
fi
if [[ ${#matches[@]} -gt 1 ]]; then
  echo "Query '$query' matches multiple — narrow it:"
  for m in "${matches[@]}"; do echo "  $m"; done
  exit 1
fi

name="${matches[0]}"

echo "=== debug run for $name ==="
mv "$BACKUP_PROJECTS/$name" "$LIVE_PROJECTS/$name"

rm -f "$LIVE_USAGE/session-meta"/*.json 2>/dev/null || true
rm -f "$LIVE_USAGE/facets"/*.json 2>/dev/null || true

before=$(stat -f "%m" "$REPORT_SRC" 2>/dev/null || echo 0)
echo "report.html mtime before: $before"
echo "--- launching debug TUI driver ---"
~/insights-badger/run-insights-tui-debug.exp || echo "  (expect exited non-zero)"
after=$(stat -f "%m" "$REPORT_SRC" 2>/dev/null || echo 0)
echo "report.html mtime after:  $after"

if [[ "$after" != "$before" ]] && [[ -f "$REPORT_SRC" ]]; then
  cp "$REPORT_SRC" "$REPORTS/$name.html"
  echo "saved $REPORTS/$name.html"
else
  echo "report.html did NOT change"
fi

echo
echo "Project left LIVE at $LIVE_PROJECTS/$name."
echo "Re-park everything with: ~/insights-badger/backup-projects.sh"
