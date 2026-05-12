## Origin of the toolkit's approach
#### I tried to get this working via Usage-data folder:
`~/.claude/usage-data/session-meta/` and `~/.claude/usage-data/facets/`

Had the agent do some online research...

#### Projects folder for the win:

The "move directories in and out of `~/.claude/projects/` to scope `/insights`" approach comes from the **"Current workaround" section** of the feature request asking for native project-scoping: [anthropics/claude-code#23762 — Current workaround](https://github.com/anthropics/claude-code/issues/23762#current-workaround). The OP describes it as:

> Manually renaming/moving folders under `~/.claude/projects/` before running `/insights` to hide unwanted projects from the ingestion stage. This is fragile and tedious.

This toolkit is the automated version of that fragile/tedious workaround. The issue was closed as a duplicate of [#23311](https://github.com/anthropics/claude-code/issues/23311), and as of writing there's still no built-in scoping flag.

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

The encoded names match Claude's own convention: `/Users/you/foo` → `-Users-you-foo`. See [docs/USAGE.md](docs/USAGE.md) for the caching tradeoff (spoiler: this approach re-pays for Haiku-extracted facets each loop, but it's pennies).