## what order do I run everything in?

Run these from inside `~/insights-badger/`.

#### One-time setup
  1. ./list-projects.sh — see what's available and pick project substrings.
  2. ./backup-usage-data.sh — moves all sessions to ~/backup/. /insights now shows nothing.

#### 3. alt — automated loop
  ./insights-per-project.sh — runs steps 3–5 below for every project in backup, driving the Claude Code TUI via `expect` (run-insights-tui.exp) to fire /insights and waiting for report.html to regenerate. Each project's report is copied to ~/backup/reports/report-<slug>.html. The expect script has a 120s timeout per project; if your machine is slow or /insights takes longer, bump the arg in insights-per-project.sh.

#### Per project (manual)
  3. ./restore-one.sh <project-substring> — pulls that project's sessions into usage-data/.
  4. Run /insights in Claude Code.
  5. ./backup-usage-data.sh — sweeps them back to ~/backup/ to start clean for the next.
  6. Repeat 3–5 for the next project.

#### When done
  7. ./restore-all.sh — restores everything so normal /insights works again.

  You can run ./list-projects.sh at any point — it scans both locations.
