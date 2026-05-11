#!/usr/bin/env bash
set -euo pipefail

LIVE="$HOME/.claude/usage-data"
BACKUP="$HOME/backup"
REPORTS="$BACKUP/reports"
REPORT_SRC="$LIVE/report.html"

mkdir -p "$REPORTS"

if [[ ! -d "$BACKUP/session-meta" ]] || [[ -z "$(ls -A "$BACKUP/session-meta" 2>/dev/null)" ]]; then
  echo "Nothing in $BACKUP/session-meta. Run ~/insights-badger/backup-usage-data.sh first."
  exit 1
fi

projects=$(
  for f in "$BACKUP/session-meta"/*.json; do
    sed -n 's/.*"project_path": *"\([^"]*\)".*/\1/p' "$f" | head -1
  done | sort -u
)

if [[ -z "$projects" ]]; then
  echo "No projects found in backup."
  exit 1
fi

echo "Projects to process:"
echo "$projects" | sed 's/^/  /'
echo

while IFS= read -r project; do
  [[ -z "$project" ]] && continue
  slug=$(echo "$project" | tr '/' '_' | sed 's/^_//')

  echo "=== $project ==="
  ~/insights-badger/restore-one.sh "$project" || { echo "skip: restore failed"; continue; }

  echo "running /insights via TUI ..."
  before=$(stat -f "%m" "$REPORT_SRC" 2>/dev/null || echo 0)
  ~/insights-badger/run-insights-tui.exp 120 || echo "  (expect script timed out or failed)"
  after=$(stat -f "%m" "$REPORT_SRC" 2>/dev/null || echo 0)

  if [[ "$after" != "$before" ]] && [[ -f "$REPORT_SRC" ]]; then
    cp "$REPORT_SRC" "$REPORTS/report-$slug.html"
    echo "  saved $REPORTS/report-$slug.html"
  else
    echo "  report.html did NOT change — TUI driver may need tuning"
  fi

  ~/insights-badger/backup-usage-data.sh >/dev/null
  echo
done <<< "$projects"

echo "Done. Reports in $REPORTS/"
ls -1 "$REPORTS"
