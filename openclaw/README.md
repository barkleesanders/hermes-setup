# openclaw/

[OpenClaw](https://docs.openclaw.ai) is the scheduling layer. In this
repo's architecture, OpenClaw handles the *LLM half* of cron — anything
that needs the model — and launchd handles the *deterministic-shell half*.

## What's here

| File | Purpose |
|---|---|
| `openclaw.example.json` | Minimal `~/.openclaw/openclaw.json` template. The real config is ~17KB; this is just enough to boot. See upstream docs for the full schema. |
| `cron-examples.md` | Sanitized example scheduled prompts — the shape, not the contents, of jobs that actually pay for their tokens. |

## What's NOT here

| Path | Why omitted |
|---|---|
| My actual `openclaw.json` | Contains real Telegram chat IDs, API account identifiers, and workspace paths. Too risky to scrub cleanly. |
| My actual `cron/jobs.json` | Real scheduled prompts reference case-specific paths, recipient IDs, and project names. |
| `~/.openclaw/credentials/`, `.env`, `auth-profiles.json` | Self-evidently. |
| `~/.openclaw/lcm.db`, `sessions/`, `logs/` | Runtime state and full transcripts. |

## Where this fits

```
~/.hermes/                        ~/.openclaw/
├── config.yaml          ←→       ├── openclaw.json
├── cron/jobs.json                ├── cron/jobs.json
├── SOUL.md                       ├── agents/
└── (everything else              └── (everything else
    hermes-agent writes)              openclaw writes)
```

- `~/.hermes/` is hermes-agent's home (LLM runtime, sessions, memory).
- `~/.openclaw/` is OpenClaw's home (scheduler, agent definitions, node).
- They cooperate: OpenClaw schedules → hermes-agent (or the bundled
  Claude/Codex agents) executes → results delivered via configured channel.

## Related

- [OpenClaw upstream docs](https://docs.openclaw.ai) — full schema and CLI reference.
- [OpenClawBS](https://github.com/barkleesanders/OpenClawBS) — the generic
  Mac mini scheduling reference architecture this repo is one concrete
  instance of.
- [../launchd/](../launchd/) — the deterministic-shell companion.
