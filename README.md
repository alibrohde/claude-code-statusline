# Claude Code Status Line

A custom status line for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that shows your current directory, model, context window usage, and **today's API spend** — right in the terminal.

```
myproject | Opus 4.6 | ctx: 32.5% | today: $5.43
```

## What it shows

| Segment | Description |
|---------|-------------|
| `myproject` | Current working directory (basename) |
| `Opus 4.6` | Active model |
| `ctx: 32.5%` | Context window usage (with `!` / `!!` / `!!!` warnings at 50/75/90%) |
| `today: $5.43` | Today's cumulative API spend via [ccusage](https://github.com/ryoppippi/ccusage) |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- [ccusage](https://github.com/ryoppippi/ccusage) — `npm install -g ccusage`

## Setup

**1. Copy the script:**

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

**2. Configure Claude Code to use it:**

```bash
claude config set statusLine '{"type":"command","command":"bash ~/.claude/statusline-command.sh"}'
```

That's it. The status line appears at the bottom of your Claude Code terminal.

## How it works

Claude Code pipes JSON context (current directory, model name, context usage percentage) to the status line command via stdin. The script parses that and appends today's spend by calling `ccusage`.

The spend value is cached for 60 seconds at `/tmp/.ccusage_daily_cache` so it doesn't slow down rendering. The cache resets automatically each day.

## Customization

The context warning thresholds are easy to change — look for the `used_int` comparisons in the script:

- `>= 50%` → `[!]`
- `>= 75%` → `[!!]`
- `>= 90%` → `[!!!]`

To change the cache duration, edit the `60` in `[ "$cache_age" -ge 60 ]`.

## Note on `stat`

The script handles both macOS (`stat -f %m`) and Linux (`stat -c %Y`) for file modification time.
