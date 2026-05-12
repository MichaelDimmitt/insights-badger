# insights-badger 🦡

> Stubborn little scripts that wrangle Claude Code's `/insights` into giving you **one report per project** instead of one giant smoothie of every codebase you've ever touched.

```
    .--.   .--.
   ( o.o ) ( o.o )         badger.
    > ^ <   > ^ <          badger.
    /   \   /   \          badger.
   /_____\ /_____\         mushroom!
```

---

## What is `/insights`?

`/insights` is a built-in Claude Code command that scans your last ~30 days of sessions, runs them through Claude Haiku to extract qualitative "facets" (satisfaction, goal type, friction points), and dumps an interactive HTML report at `~/.claude/usage-data/report.html`. It tells you things like *"Claude misunderstood your request on the first try in 47% of sessions"* and *"here's a CLAUDE.md rule you should add."*

It's great. There's just **one** problem.

## The problem this fixes

`/insights` analyzes **every project at once**. If you have a fintech monorepo with 200 sessions and a side project with 12, the fintech work drowns out everything else. The friction patterns and CLAUDE.md suggestions you get are an average across codebases that have nothing in common.

There's no `--project` flag. The [open feature request][upstream-issue] was closed as a duplicate. Until Anthropic ships scoping natively, your only option is the workaround the OP described:

> Manually renaming/moving folders under `~/.claude/projects/` before running `/insights` to hide unwanted projects from the ingestion stage. This is fragile and tedious.

This repo is the un-fragile, un-tedious version. We park every project except one, run `/insights`, save the report, re-park it, repeat. You end up with `results/<project>.html` for every project. Open them all at once. 🦡

[upstream-issue]: https://github.com/anthropics/claude-code/issues/23762#current-workaround

## Quickstart

```bash
{
git clone https://github.com/MichaelDimmitt/insights-badger ~/insights-badger
cd ~/insights-badger

./scripts/list-projects.sh           # see what's there
./scripts/backup-projects.sh         # park everything
./scripts/insights-per-project.sh    # the magic loop — get a coffee
./scripts/open.sh results/*          # admire your collection of reports
./scripts/restore-all.sh             # back to normal /insights
}
```

That's it. Everything below is detail.

**Full step-by-step:** [docs/WORKFLOW.md](docs/WORKFLOW.md) — the same flow broken into one-time setup / loop vs single-project / exit, plus directory layout.

**Dependencies:** Needs `bash`, `expect`, and the `claude` CLI. macOS works out of the box; Linux/WSL needs `apt install expect`; Windows needs WSL. Full per-OS install table and known quirks in [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md).

## ⚠️ Heads up — this uses your usage budget

`/insights` runs Claude Haiku against every session to extract "facets" (qualitative tags). Because this toolkit clears the `~/.claude/usage-data/facets/` cache between every project, **every project in the loop re-pays for facet extraction from scratch** — no cross-project reuse.

Rough math: if you have N projects with ~M sessions each, expect N × M Haiku calls per full loop, where a normal `/insights` run would pay once and cache. Haiku is cheap so this is usually pennies, but if you're on a metered API plan or close to a Claude.ai subscription quota, **the loop can chew through your budget faster than you expect** — especially the first run on a fresh machine. Subsequent runs are no cheaper because the cache is wiped each time.

If this matters to you: see [docs/NOTES.md](docs/NOTES.md) for the full tradeoff and a sketch of how the loop could be changed to keep the facet cache between iterations.

## The commands

| Script | What it does |
|---|---|
| `list-projects.sh` | Show which projects are live in `~/.claude/projects/` vs parked in `~/backup/projects/`. Safe to run anytime. |
| `backup-projects.sh` | Move every project out of `~/.claude/projects/` and into `~/backup/projects/`. Clears the `usage-data/` caches so `/insights` starts clean. |
| `insights-per-project.sh` | **The main event.** For every parked project: restore → clear caches → drive `/insights` via `expect` → save `report.html` → re-park. Set `STOP_ON_FAIL=1` to halt on the first failure with the project left live for debugging. |
| `restore-one.sh <substring>` | Same flow but for one project only, left **live** afterwards so you can poke around. |
| `restore-all.sh` | Exit the toolkit. Moves every parked project back into `~/.claude/projects/` so normal multi-project `/insights` works again. |
| `open.sh <files-or-glob>` | Cross-platform file opener. `./scripts/open.sh results/*` opens every generated HTML report in your browser. Works on macOS, Linux, WSL, and Git Bash. |
| `run-insights-tui.exp` | The `expect` driver that talks to Claude Code's TUI. You shouldn't need to call this directly. |

## How it works

```
                     ┌─────────────────────────────────────┐
                     │  ~/.claude/projects/                │  <- LIVE: what /insights sees
                     │    -Users-you-fintech-monorepo/     │
                     │    -Users-you-side-project/         │
                     └─────────────────────────────────────┘
                                       │
                                  backup-projects.sh
                                       ▼
                     ┌─────────────────────────────────────┐
                     │  ~/backup/projects/                 │  <- PARKED: hidden from /insights
                     │    -Users-you-fintech-monorepo/     │
                     │    -Users-you-side-project/         │
                     └─────────────────────────────────────┘
                                       │
                            insights-per-project.sh loop:
                              for each project:
                                move back to live
                                clear ~/.claude/usage-data/
                                run /insights via expect
                                copy report.html to results/
                                re-park
                                       ▼
                     ┌─────────────────────────────────────┐
                     │  ~/insights-badger/results/         │  <- your per-project reports
                     │    -Users-you-fintech-monorepo.html │
                     │    -Users-you-side-project.html     │
                     └─────────────────────────────────────┘
```

The encoded names match Claude's own convention: `/Users/you/foo` → `-Users-you-foo`. See [docs/NOTES.md](docs/NOTES.md) for the caching tradeoff (spoiler: this approach re-pays for Haiku-extracted facets each loop, but it's pennies).

## Repo layout

```
insights-badger/
├── Readme.md
├── scripts/                # all the .sh and the .exp driver
├── docs/                   # NOTES.md — origin story, caching tradeoff
├── results/                # gitignored — your generated HTML reports land here
└── .github/ISSUE_TEMPLATE/ # bug + feature templates
```

## Future ideas

PRs welcome on any of these:

- **Facet cache reuse.** Don't nuke `~/.claude/usage-data/facets/` between projects — facets are keyed by session ID and would be reused across loop iterations. Save Haiku tokens. See [docs/NOTES.md](docs/NOTES.md).
- **Aggregate report.** Stitch every `results/*.html` into one index page with per-project tiles and rolled-up friction stats across the whole portfolio.
- **`--project` flag stub.** A wrapper that takes a substring and behaves like `/insights --project <substring>` would, so you can stop thinking about backup/restore at all.
- **CI mode.** Run weekly, drop reports into a dated folder, diff against last week's friction patterns. "Are we getting better or worse at working with Claude?"
- **Linux/WSL hardening.** The current scripts use `stat -f` (BSD/macOS). A `stat -c` fallback for GNU coreutils would un-break this on Linux.
- **Make this repo obsolete.** Upvote [the upstream feature request][upstream-issue]. If `/insights --project` ships natively, delete this repo.

## Reporting a bug 🐛

Found something broken? Please [open an issue](../../issues/new/choose) using the bug report template — it asks for your OS, shell, Claude Code version, and which script broke. Most issues in this repo are OS-specific (looking at you, `stat -f`), so that info is the difference between "fixed in 5 minutes" and "we'll never reproduce this."

For feature ideas, the feature request template is much lighter.

## License & spirit

Hack on it however you want. This is a workaround for a thing that should be built-in — the goal is for the upstream issue to get fixed and for this repo to become a charming relic. Until then: badger badger badger. 🦡

---

<sub>Built because `/insights` is too good to be averaged across 11 unrelated codebases.</sub>
