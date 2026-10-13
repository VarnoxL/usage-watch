# usage-watch

A plan-usage check for AI coding agents: how much of your usage window is
used up, and when it resets. Companion tool to
[context-watch](https://github.com/VarnoxL/context-watch), which covers
per-session context-window tokens instead of plan usage.

```
rollout-2026-10-12T09-00-00-....jsonl  (plan: plus)
[######----] 62% used - 5.0-hour window, resets in 2h 14m (2026-10-12 11:14)
[##--------] 23% used - 7.0-day window, resets in 3d 9h (2026-10-15 09:00)
```

Windows / PowerShell only for now.

## Codex CLI

Codex CLI logs real plan-usage snapshots (percent used, window length, reset
time) straight into your local session files whenever the API reports them.
This script finds the most recent snapshot and prints it.

```
powershell -ExecutionPolicy Bypass -File codex-usage.ps1
```

No statusline hook exists for Codex CLI, so this is run on demand rather than
shown live.

## Why not Claude Code?

Claude Code's own usage banner (`/status`) is fetched live from the API on
demand and is never written to any local file — there's no cache to read it
from after the fact. Faking a number from local token counts would be a
guess, not your actual plan usage, so this tool doesn't support Claude Code.
(For Claude Code's *context-window* usage, which **is** available locally,
see [context-watch](https://github.com/VarnoxL/context-watch) instead.)

## Why not other agents (Cursor, Windsurf, ...)?

Same reasoning as context-watch: they don't expose usage data via any local
file or API today, so there's no real data to show.
