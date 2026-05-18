# launchd/

macOS LaunchAgent plists for the deterministic-shell half of the architecture.

## When to use launchd (this dir) vs OpenClaw cron (../openclaw/)

| Use launchd when... | Use OpenClaw cron when... |
|---|---|
| A `bash` one-liner does it (`git pull`, `rsync`, `curl`, `pg_dump`) | An LLM has to reason, browse, or summarize |
| The work has no fuzzy judgment (`systemctl restart`, file rotation) | Output depends on context (yesterday's emails, new GitHub issues) |
| You'd waste agent tokens running it | Skipping the model would mean writing a brittle scraper |

**Rule of thumb**: burning Anthropic / OpenAI tokens on a deterministic
shell job is pure waste. If you wouldn't pay a contractor to do it, don't
pay the model. Use launchd.

## What's here

| File | Purpose |
|---|---|
| `ai.hermes.gateway.plist` | The hermes-agent gateway daemon. Loaded at login, auto-restarts on crash. Required for everything else hermes does. |
| `com.example.daily-backup.plist` | Pattern: a nightly deterministic shell job. Copy, rename, change `ProgramArguments`. |

## Install

```bash
# Copy a plist to ~/Library/LaunchAgents, edit <HOME>, then load:
cp launchd/ai.hermes.gateway.plist ~/Library/LaunchAgents/
sed -i.bak "s|<HOME>|$HOME|g" ~/Library/LaunchAgents/ai.hermes.gateway.plist
launchctl unload ~/Library/LaunchAgents/ai.hermes.gateway.plist 2>/dev/null
launchctl load   ~/Library/LaunchAgents/ai.hermes.gateway.plist
launchctl list | grep hermes      # confirm loaded
```

## Useful launchctl commands

```bash
launchctl list | grep <label>                              # is it loaded?
launchctl print gui/$(id -u)/<label> | head -40            # full status incl. last exit code
launchctl kickstart -k gui/$(id -u)/<label>                # force a restart
launchctl unload ~/Library/LaunchAgents/<label>.plist      # stop and unregister
```

## Gotchas

- **`StartCalendarInterval`** schedules in the user's local timezone, not UTC.
  Confirm with `sudo systemsetup -gettimezone`.
- **`KeepAlive: true`** restarts the job immediately on exit, even with
  `RunAtLoad: false`. Use the `SuccessfulExit: false` sub-key (as in
  `ai.hermes.gateway.plist`) if you only want to restart on crash.
- **Missed runs on sleep**: launchd will run a missed `StartCalendarInterval`
  job once when the machine wakes. Plain user `crontab` will not — it just
  skips. This is the main reason I use launchd over cron on a Mac mini.
- **Log paths must exist**: launchd will silently fail if the parent
  directory of `StandardOutPath` doesn't exist. Always
  `mkdir -p ~/.local/log` or equivalent before loading.
- **Env vars**: launchd doesn't inherit your shell environment. Anything
  you need (PATH, API keys) must be in the plist's `EnvironmentVariables`
  block or sourced from a wrapper script.
