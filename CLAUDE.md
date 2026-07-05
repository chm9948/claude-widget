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

## Build & verify

- Rebuild: `Invoke-ps2exe -inputFile claude-widget.ps1 -outputFile claude-widget.exe -noConsole -iconFile claude-widget.ico` — **must** pass `-iconFile` or the app/tray icon is lost.
- Kill the running widget first (`Get-Process claude-widget | Stop-Process -Force`); ps2exe can't overwrite a running exe (Access denied).
- Syntax-check before building: `[System.Management.Automation.Language.Parser]::ParseFile(path,[ref]$t,[ref]$e)`.
- XAML/FindName/init errors do NOT show at syntax-check — launch the exe and confirm the process stays alive ~4 s.
- On completion, copy `claude-widget.ps1` → `claude-widget.backup.ps1`.

## Gotchas

- The exe runs on **PowerShell 5.1 Desktop**; diagnostic shells are often PS7. `ConvertFrom-Json` parses ISO dates differently (PS5.1 keeps `…Z` as String; `+00:00` may become DateTime) — always `[DateTimeOffset]::Parse([string]$x)`.
- PowerShell `[int]` **rounds**, not truncates — use `[math]::Floor` for hour/time math.
- Running the `.ps1` directly needs STA: use `powershell` (5.1), not `pwsh` (PS7=MTA → WPF fails).

## Data Source

Two sources, merged in the background runspace every **5 minutes** (300 s; a manual refresh trigger wakes it sooner):

1. **ccusage** — `npx ccusage@latest claude monthly --json` (monthly cost + model breakdown) and `... blocks --json` (active-block cost). Read from local `~/.claude/projects/**/*.jsonl`, so it only sees Claude Code CLI usage.
2. **Anthropic usage API** — `GET https://api.anthropic.com/api/oauth/usage` with the OAuth `accessToken` from `~/.claude/.credentials.json` (header `anthropic-beta: oauth-2025-04-20`). Its `five_hour.resets_at` and `five_hour.utilization` are the exact values `/usage` shows, and they account for **all** clients (browser, desktop app), not just the CLI.

The runspace puts `apiBlockEndUtc` (from `five_hour.resets_at`) and `apiBlockPct` (from `five_hour.utilization`) into the enqueued JSON. `Update-Display` prefers these for the block end time and progress %, falling back to ccusage `endTime` and the `max(tokens/20,446,221, cost/13.44)` formula only when the API call fails (e.g. expired token while Claude Code isn't running to refresh it). Results reach the UI thread via a `ConcurrentQueue<string>`, polled every 2 seconds by a `DispatcherTimer`.

> Why the API matters: the billing block starts at the first API call across *all* clients. JSONL only records CLI calls, so on days that start in the browser the JSONL-derived block end was up to ~1h late. The API is server-side truth and eliminates that error.

The usage API result is cached across loop iterations: on failure (e.g. HTTP 429) the last good `apiBlockEndUtc`/`apiBlockPct` keep being shown instead of falling back to the divergent ccusage formula, with a 15-min backoff (other errors 5 min) before retrying.

## Update check & distribution

- **Version check**: once per hour the runspace fetches the repo's raw `CHANGELOG.md` and extracts the top `## [vX.Y.Z]` heading. If it's newer than `$script:appVersion`, `Update-Display` shows a red dot on the ⓘ button **and the tray icon** plus an "vX.Y.Z 로 업데이트" link in the ⓘ panel.
- **One-click update**: clicking that link launches `setup.ps1` in a detached PowerShell (`iex (irm …/setup.ps1)`), which stops the running widget, re-downloads the latest exe to `%LOCALAPPDATA%\ClaudeWidget`, and relaunches.
- **`setup.ps1`**: per-user installer (no admin). Downloads the exe (no Mark-of-the-Web → no SmartScreen), `Unblock-File`s it, creates a Start Menu shortcut, launches it. `$ClaudeWidgetUninstall=$true` before invoking runs uninstall (removes folder, shortcut, Run-key entry).
- Auto-start is a `HKCU\…\Run` entry toggled from the tray right-click menu, not by the installer.

## Release flow

The committed `claude-widget.exe` on `main` **is** the distribution — `setup.ps1` and the one-click updater both download it from the raw `main` URL. To release:

1. Bump `$script:appVersion` in `claude-widget.ps1`.
2. Add a matching `## [vX.Y.Z] - YYYY-MM-DD` entry at the **top** of `CHANGELOG.md` (Keep a Changelog style, KST dates) — the update check compares against this heading, so it must equal `$script:appVersion` exactly.
3. Rebuild the exe and commit script + CHANGELOG + exe **together**: pushing the CHANGELOG bump without the rebuilt exe makes every running widget show an update that installs the old version.

## Architecture

- **Single-file WPF app** written in PowerShell. XAML is defined as an inline here-string and loaded with `XamlReader`. Started via `Application.Run()` (not `ShowDialog()`, which blocks `Show`/`Hide` needed for the tray). The window is shown explicitly on startup; `ShowInTaskbar=False`.
- **Named-element binding**: every `x:Name` in the XAML must also be listed in the `foreach` FindName block near the top of the script, which auto-creates a matching camelCase `$script:` variable (e.g. `BlockPct` → `$script:blockPct`). Adding a named element without registering it there silently yields `$null` (caught only by launching the exe, not by syntax check).
- **Repo constants**: `$script:repoOwner`/`$script:repoName` at the top of the script derive the GitHub/raw URLs used by the update check, issue link, and one-click updater — nothing else hardcodes the repo (except `setup.ps1`, which has its own URL).
- **System tray** uses WinForms `NotifyIcon` (`Add-Type System.Windows.Forms`/`System.Drawing`). Left-click toggles show/hide, right-click menu = 열기/숨기기/자동실행/종료, header ✕ hides to tray (only the menu's 종료 closes the window → app exit). The "update available" red-dot variant icon is drawn at runtime from the base icon. `NotifyIcon` is disposed in the window's `Closed` handler.
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
