# Requirements

## Tools

| Need | macOS | Linux / WSL | Windows |
|---|---|---|---|
| `claude` CLI | install from [claude.com/download](https://claude.com/download) | install from [claude.com/download](https://claude.com/download) | install from [claude.com/download](https://claude.com/download) |
| `bash` 3.2+ | preinstalled | preinstalled | Git Bash or WSL |
| `expect` | preinstalled | `apt install expect` / `dnf install expect` / `pacman -S expect` | use WSL (Git Bash does not ship `expect`) |
| Opener for `open.sh` | `open` (preinstalled) | `xdg-open` (preinstalled on desktops) or `wslview` (`apt install wslu` on WSL) | `start` (preinstalled in Git Bash) |

## Disk layout

The toolkit assumes the standard Claude Code paths:

- `~/.claude/projects/` — source transcripts (must exist; `/insights` won't work without it)
- `~/.claude/usage-data/` — generated/cleared by the toolkit
- `~/backup/projects/` — created on first `backup-projects.sh` run

The repo itself must live at `~/insights-badger/` because the scripts use that absolute path for cross-script calls. (Open to a PR that makes this relative — see Future ideas.)

## Known OS quirks

### `stat -f "%m"` on Linux

The scripts read `report.html`'s mtime with `stat -f "%m"`, which is BSD/macOS syntax. GNU coreutils (Linux) needs `stat -c "%Y"`. As written, the call silently falls through to `echo 0` on Linux:

```bash
before=$(stat -f "%m" "$REPORT_SRC" 2>/dev/null || echo 0)
```

This means the mtime-change check still **functions** on Linux (because `0 != $after` once the report regenerates), but you'll see `report.html mtime before: 0` in the output regardless of whether the file already existed. Cosmetic but confusing.

Fix is tracked under "Linux/WSL hardening" in the Readme's Future ideas.

### `expect` on Windows

`expect` is a Tcl extension and is not shipped in Git Bash or MSYS2 by default. The realistic options on Windows are:

1. **WSL** (recommended) — install your distro's `expect` package, then `wslu` for `wslview`. The toolkit runs as if you were on Linux.
2. **MSYS2** — `pacman -S expect` works, but you'll still hit the `stat -f` issue and may need to fight TTY/PTY emulation for the TUI driver.

### Apple `bash` 3.2 vs newer bash

Apple ships bash 3.2 (last release before bash 4 went GPLv3). The scripts intentionally stick to features that work on 3.2 — arrays, `[[ ]]`, `shopt -s nullglob`, parameter expansion. If you've installed a newer bash via Homebrew, everything still works; we just don't *require* it.

## How to verify your setup

```bash
claude --version       # any recent version
bash --version         # 3.2 or newer
expect -v              # any version
```

If all three print something sensible, you're good to go.
