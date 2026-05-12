#!/usr/bin/env bash
set -euo pipefail

# Loop over every parked project in ~/backup/projects/. For each:
#   - move it back into ~/.claude/projects/
#   - clear usage-data so /insights rebuilds clean
#   - run /insights via the expect TUI driver
#   - copy the regenerated report.html to ~/backup/reports/report-<slug>.html
#   - move the project back to ~/backup/projects/
#
# Expect driver is independent of the layer fix; if it times out per project,
# bump the first arg below (currently 120 seconds).

LIVE_PROJECTS="$HOME/.claude/projects"
LIVE_USAGE="$HOME/.claude/usage-data"
BACKUP_PROJECTS="$HOME/backup/projects"
REPORTS="$HOME/backup/reports"
REPORT_SRC="$LIVE_USAGE/report.html"
TIMEOUT="${TIMEOUT:-120}"

mkdir -p "$REPORTS" "$LIVE_PROJECTS" "$LIVE_USAGE/session-meta" "$LIVE_USAGE/facets"

if [[ ! -d "$BACKUP_PROJECTS" ]] || [[ -z "$(ls -A "$BACKUP_PROJECTS" 2>/dev/null)" ]]; then
  echo "Nothing in $BACKUP_PROJECTS. Run backup-projects.sh first."
  exit 1
fi

shopt -s nullglob
echo "Projects to process:"
for d in "$BACKUP_PROJECTS"/*/; do
  echo "  $(basename "$d")"
done
echo

for d in "$BACKUP_PROJECTS"/*/; do
  name=$(basename "$d")
  slug="${name#-}"

  echo "=== $name ==="
  mv "$d" "$LIVE_PROJECTS/$name"

  rm -f "$LIVE_USAGE/session-meta"/*.json 2>/dev/null || true
  rm -f "$LIVE_USAGE/facets"/*.json 2>/dev/null || true

  echo "running /insights via TUI ..."
  before=$(stat -f "%m" "$REPORT_SRC" 2>/dev/null || echo 0)
  ~/insights-badger/run-insights-tui.exp "$TIMEOUT" || echo "  (expect script timed out or failed)"
  after=$(stat -f "%m" "$REPORT_SRC" 2>/dev/null || echo 0)

  if [[ "$after" != "$before" ]] && [[ -f "$REPORT_SRC" ]]; then
    cp "$REPORT_SRC" "$REPORTS/report-$slug.html"
    echo "  saved $REPORTS/report-$slug.html"
  else
    echo "  report.html did NOT change — TUI driver may need tuning"
  fi

  mv "$LIVE_PROJECTS/$name" "$BACKUP_PROJECTS/$name"
  echo
done

rm -f "$LIVE_USAGE/session-meta"/*.json 2>/dev/null || true
rm -f "$LIVE_USAGE/facets"/*.json 2>/dev/null || true

echo "Done. Reports in $REPORTS/"
ls -1 "$REPORTS"
