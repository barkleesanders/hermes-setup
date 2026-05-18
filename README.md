# hermes-setup

My Mac mini deployment of [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) — "the agent that grows with you."

This is the sanitized public scaffolding for how I run hermes-agent unattended on a Mac mini at home: launchd timers for deterministic shell, [OpenClaw](https://docs.openclaw.ai) for scheduled Claude agent invocations, and the glue between them.

It's the unattended companion to my interactive Claude Code setup in [claude-code-starter](https://github.com/barkleesanders/claude-code-starter).

## What this is (and isn't)

**Is:** patterns, scaffolding, install scripts, sanitized config templates, plist examples, the operating model.

**Isn't:** my actual cron payloads, real hostnames, real Telegram chat IDs, case-specific scripts, or anything that names real people. That stays in a private `hermes-backup` repo behind git-crypt. See claude-code-starter's [Privacy section](https://github.com/barkleesanders/claude-code-starter#privacy--pii-boundaries) for the same firewall pattern.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Mac mini (always on)                                    │
│                                                          │
│  ┌──────────────────────────┐                           │
│  │ hermes-agent             │  ← grows with use         │
│  │ (NousResearch)           │     Anthropic API direct  │
│  └──────────────────────────┘                           │
│              ▲                                           │
│              │ invoked by                                │
│              │                                           │
│  ┌─────────────────────┐   ┌─────────────────────────┐  │
│  │ OpenClaw            │   │ launchd                 │  │
│  │ (LLM scheduling)    │   │ (shell scheduling)      │  │
│  │ "agent cron"        │   │ "deterministic cron"    │  │
│  └─────────────────────┘   └─────────────────────────┘  │
│              │                       │                   │
│              └───────────┬───────────┘                   │
│                          │                               │
│                  ~/.claude/                              │
│              (skills, agents, hooks,                     │
│               shared with the laptop)                    │
└─────────────────────────────────────────────────────────┘
                          │
                          │ Tailscale
                          ▼
                  Laptop (interactive)
                  claude-code-starter
```

## Operating model (two rules)

1. **`openclaw cron` is ONLY for LLM work.** Agent turns, browsing, summarization, code review on a PR queue. Anything that needs the model.
2. **Pure shell work goes in launchd plists.** `git pull`, `rsync`, `curl`, `systemctl restart`. Burning agent tokens on deterministic shell is pure waste.

This split is what makes the combined cost sustainable.

## Layout

```
hermes-setup/
├── README.md                       # you are here
├── LICENSE                          # MIT
├── install.sh                       # idempotent installer; refuses to run with leftover <PLACEHOLDER>s
├── .gitignore                       # blocks .env, secrets, runtime state
│
├── hermes/                          # sanitized ~/.hermes/ templates
│   ├── README.md
│   ├── config.example.yaml          # ~/.hermes/config.yaml template
│   └── SOUL.example.md              # ~/.hermes/SOUL.md template (operator personality)
│
├── launchd/                         # macOS LaunchAgent plists
│   ├── README.md                    # launchd vs openclaw cron, gotchas, useful commands
│   ├── ai.hermes.gateway.plist      # hermes-cli gateway daemon (real, sanitized)
│   └── com.example.daily-backup.plist  # sample deterministic shell job
│
├── openclaw/                        # scheduling patterns
│   ├── README.md
│   ├── openclaw.example.json        # minimal ~/.openclaw/openclaw.json template
│   └── cron-examples.md             # 3 sanitized scheduled-prompt patterns
│
└── tools/                           # generic glue
    ├── README.md
    └── hermes-doctor.sh             # health check; supports --remote <ssh-host>
```

## Install

```bash
git clone https://github.com/barkleesanders/hermes-setup.git
cd hermes-setup

# Preview what install.sh would do without writing anything:
./install.sh --dry-run

# Run for real:
./install.sh
```

The installer refuses to overwrite existing `~/.hermes/config.yaml` or
`~/Library/LaunchAgents/ai.hermes.gateway.plist`, so re-running it is safe.

After install:

```bash
hermes-cli auth login                          # if you haven't already
$EDITOR ~/.hermes/config.yaml                  # tune the kawaii/cost knobs
$EDITOR ~/.hermes/SOUL.md                      # set operator personality
./tools/hermes-doctor.sh                       # should be all green
```

## Related

- **[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)** — the upstream agent runtime this repo deploys.
- **[claude-code-starter](https://github.com/barkleesanders/claude-code-starter)** — the interactive `~/.claude/` config that hermes-agent shares. Same skills, agents, hooks; different invocation context.
- **[OpenClawBS](https://github.com/barkleesanders/OpenClawBS)** — the generic Mac mini scheduling reference architecture. `hermes-setup` is one concrete instance of that pattern.
- **[OpenClaw](https://docs.openclaw.ai)** — the scheduler used by both.

## License

MIT. See [LICENSE](LICENSE).
