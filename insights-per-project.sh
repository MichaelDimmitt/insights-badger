#!/usr/bin/env bash
set -euo pipefail

# For each parked project in ~/backup/projects/:
#   - move it back into ~/.claude/projects/
#   - clear usage-data so /insights rebuilds clean
#   - run /insights via the expect TUI driver (full TUI output to terminal)
#   - copy the regenerated report.html to ~/insights-badger/results/<name>.html
#   - move the project back to ~/backup/projects/
#
# Env vars:
#   STOP_ON_FAIL=1   halt the loop when a project fails (expect non-zero OR
#                    report.html unchanged) and LEAVE that project live so you
#                    can re-run the expect driver against it manually.

LIVE_PROJECTS="$HOME/.claude/projects"
LIVE_USAGE="$HOME/.claude/usage-data"
BACKUP_PROJECTS="$HOME/backup/projects"
REPORTS="$HOME/insights-badger/results"
REPORT_SRC="$LIVE_USAGE/report.html"
STOP_ON_FAIL="${STOP_ON_FAIL:-0}"

mkdir -p "$REPORTS" "$LIVE_PROJECTS" "$LIVE_USAGE/session-meta" "$LIVE_USAGE/facets"

if [[ ! -d "$BACKUP_PROJECTS" ]] || [[ -z "$(ls -A "$BACKUP_PROJECTS" 2>/dev/null)" ]]; then
  echo "Nothing in $BACKUP_PROJECTS. Run backup-projects.sh first."
  exit 1
fi

shopt -s nullglob
echo "Projects to process (debug mode):"
for d in "$BACKUP_PROJECTS"/*/; do
  echo "  $(basename "$d")"
done
echo

for d in "$BACKUP_PROJECTS"/*/; do
  name=$(basename "$d")

  echo "=== $name ==="
  mv "$d" "$LIVE_PROJECTS/$name"

  rm -f "$LIVE_USAGE/session-meta"/*.json 2>/dev/null || true
  rm -f "$LIVE_USAGE/facets"/*.json 2>/dev/null || true

  before=$(stat -f "%m" "$REPORT_SRC" 2>/dev/null || echo 0)
  echo "report.html mtime before: $before"
  echo "--- launching debug TUI driver ---"
  expect_rc=0
  ~/insights-badger/run-insights-tui.exp || expect_rc=$?
  [[ "$expect_rc" -ne 0 ]] && echo "  (expect exited $expect_rc)"
  after=$(stat -f "%m" "$REPORT_SRC" 2>/dev/null || echo 0)
  echo "report.html mtime after:  $after"

  failed=0
  if [[ "$after" != "$before" ]] && [[ -f "$REPORT_SRC" ]]; then
    cp "$REPORT_SRC" "$REPORTS/$name.html"
    echo "  saved $REPORTS/$name.html"
  else
    echo "  report.html did NOT change"
    failed=1
  fi
  [[ "$expect_rc" -ne 0 ]] && failed=1

  if [[ "$failed" -eq 1 ]] && [[ "$STOP_ON_FAIL" == "1" ]]; then
    echo
    echo "STOP_ON_FAIL=1 — halting. Project left LIVE at $LIVE_PROJECTS/$name."
    echo "Re-run manually with: ~/insights-badger/run-insights-tui.exp"
    echo "Re-park everything when done: ~/insights-badger/backup-projects.sh"
    exit 1
  fi

  mv "$LIVE_PROJECTS/$name" "$BACKUP_PROJECTS/$name"
  echo
done

rm -f "$LIVE_USAGE/session-meta"/*.json 2>/dev/null || true
rm -f "$LIVE_USAGE/facets"/*.json 2>/dev/null || true

echo "Done. Reports in $REPORTS/"
ls -1 "$REPORTS"
