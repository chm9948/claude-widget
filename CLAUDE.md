# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Windows desktop widget (`claude-widget.ps1`) that shows Claude Code monthly costs and active billing block status in a floating WPF window. A pre-compiled binary (`claude-widget.exe`) is also distributed alongside the source.

## Running

```powershell
# Run the script directly
powershell -ExecutionPolicy Bypass -File claude-widget.ps1

# Or launch the compiled binary
.\claude-widget.exe
```

## Data Source

Two sources, merged in the background runspace every 60 seconds:

1. **ccusage** — `npx ccusage@latest claude monthly --json` (monthly cost + model breakdown) and `... blocks --json` (active-block cost). Read from local `~/.claude/projects/**/*.jsonl`, so it only sees Claude Code CLI usage.
2. **Anthropic usage API** — `GET https://api.anthropic.com/api/oauth/usage` with the OAuth `accessToken` from `~/.claude/.credentials.json` (header `anthropic-beta: oauth-2025-04-20`). Its `five_hour.resets_at` and `five_hour.utilization` are the exact values `/usage` shows, and they account for **all** clients (browser, desktop app), not just the CLI.

The runspace puts `apiBlockEndUtc` (from `five_hour.resets_at`) and `apiBlockPct` (from `five_hour.utilization`) into the enqueued JSON. `Update-Display` prefers these for the block end time and progress %, falling back to ccusage `endTime` and the `max(tokens/20,446,221, cost/13.44)` formula only when the API call fails (e.g. expired token while Claude Code isn't running to refresh it). Results reach the UI thread via a `ConcurrentQueue<string>`, polled every 2 seconds by a `DispatcherTimer`.

> Why the API matters: the billing block starts at the first API call across *all* clients. JSONL only records CLI calls, so on days that start in the browser the JSONL-derived block end was up to ~1h late. The API is server-side truth and eliminates that error.

## Architecture

- **Single-file WPF app** written in PowerShell. XAML is defined as an inline here-string and loaded with `XamlReader`.
- **Two timers on the UI thread**: `$script:pollTimer` (2 s) drains the queue and calls `Update-Display`; `$script:countdownTimer` (1 s) updates the footer countdown and block time-remaining live.
- **Background runspace** (`$script:bgRunspace`) runs `ccusage` + the usage API call in a loop and enqueues merged JSON. It never touches UI elements directly. The OAuth token is re-read from `.credentials.json` on every iteration so token refreshes by a running Claude Code are picked up automatically.
- **Themes** (`$script:themes`) are plain hashtables (`light`/`dark`) applied via `Apply-Theme`, which re-colors all named WPF elements and re-renders model rows through `Update-Display`.
- **Model rows** are built dynamically in `New-ModelRow` using inline XAML strings parsed with `XamlReader::Parse`. Each row is rebuilt from scratch on every data refresh.
- **Block progress bar** uses star-width `GridColumnDefinitions` (filled `$pct*` / empty `$(100-pct)*`). `$pct` is `five_hour.utilization` from the API; the fallback formula's 100% cap is `20_446_221` tokens / `$13.44`.

## Key Variables

| Variable | Purpose |
|---|---|
| `$script:queue` | Thread-safe channel between background runspace and UI |
| `$script:currentData` | Last parsed JSON object; re-used when re-theming |
| `$script:blockEndTime` | `[DateTime]` of active block end (local time); `$null` when no active block |
| `$script:currentTheme` | Active theme hashtable; referenced by `New-ModelRow` |
