# hermes/

Sanitized templates for the `~/.hermes/` directory that
[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
creates and reads at runtime.

## What's here

| File | Purpose |
|---|---|
| `config.example.yaml` | Template for `~/.hermes/config.yaml`. Drop in, edit `<ANGLE_BRACKETS>`, then start. |
| `SOUL.example.md` | Template for `~/.hermes/SOUL.md` — system-context "operator personality" file. Loaded on every agent turn. |

## What's NOT here (intentionally)

These live on the Mac mini and never leave it:

| Path | Why omitted |
|---|---|
| `~/.hermes/.env` | API keys, OAuth tokens. Never publish. |
| `~/.hermes/auth.json` | Provider session cookies. |
| `~/.hermes/sessions/` | Full transcripts of every agent turn. Always private. |
| `~/.hermes/state.db` | SQLite memory store with conversation history. |
| `~/.hermes/cron/jobs.json` | My actual scheduled tasks (case-specific prompts, real chat IDs). Use `openclaw/cron-examples.md` for sanitized patterns. |
| `~/.hermes/channel_directory.json` | Real Telegram/WhatsApp/Signal IDs. |
| `~/.hermes/memories/` | Long-term memory across sessions. |
| `~/.hermes/bin/` | The vendored `tirith` secrets sentinel binary (10MB). Ships with hermes-agent. |

## How `~/.hermes/` gets populated

1. Install hermes-agent (see top-level [install.sh](../install.sh)).
2. Run `hermes-cli auth login` — this writes `~/.hermes/auth.json` and `~/.hermes/.env`.
3. Run `hermes-cli config init` (or copy `config.example.yaml` to `~/.hermes/config.yaml`).
4. Optionally drop `SOUL.example.md` at `~/.hermes/SOUL.md` to set operator personality.

Subdirectories (`sessions/`, `logs/`, `cache/`, `state/`, `memories/`,
`hooks/`, `skills/`, `platforms/`, `sandboxes/`) are created and managed
by the agent itself — don't pre-create them.

## Verifying your install

```bash
hermes-cli doctor              # surfaces config errors and missing env vars
ls ~/.hermes/                   # confirm config.yaml + auth.json exist
hermes-cli gateway run          # foreground test before installing as a launchd service
```

When the foreground gateway run is clean, install the launchd plist from
[../launchd/](../launchd/) so it survives reboots.
