# What this setup actually runs

A sanitized inventory of the *shape* of work I run on my Mac mini through this setup. **No project names, case identifiers, or real recipients** — those stay private. The point of this doc is to make the public scaffolding more useful by showing the buckets a real deployment of hermes-agent + OpenClaw fills.

If you're trying to decide whether this pattern fits your needs, this is the page that tells you.

---

## Cron categories (OpenClaw — the LLM half)

These are the **bucket types** of scheduled prompts I run. Each bucket has multiple jobs underneath; only the bucket-level purpose is published. For the actual cron shape, see [openclaw/cron-examples.md](./openclaw/cron-examples.md).

| Bucket | Frequency | Why it earns LLM tokens |
|---|---|---|
| **Self-maintenance** | nightly | Drift detection across `MEMORY.md`, `TOOLS.md`, skill descriptions — text-vs-reality diffing a shell script can't do well |
| **Daily / EOD digest** | daily, end of business | Natural-language summary of beads closures, skill changes, and notable signals; judgment on what's noise vs noteworthy |
| **Issue queue triage** | 15-min during business hours | Classify GitHub/Asana issues into bug/feature/spam/dup; dedupe with comment-and-close; leave the rest for me |
| **Status watchers** | hourly to daily | Poll external systems (issue trackers, public dashboards, status pages) for state-change signals — anything where "did this flip from X to Y" requires reading prose |
| **Content monitors** | daily | RSS / social-feed scans for research signals; promote interesting items into beads with classification |
| **Backup orchestration** | nightly | Reconciliation: list expected backup artifacts, check what landed, surface gaps. Pure-shell version would either over-report or under-report |
| **Skill / config drift** | weekly | Audit `~/.claude/skills/` and `~/.hermes/` against a known-good shape; open beads issues for drift |

**Not in OpenClaw** (these run as launchd timers — see `launchd/`):

- `git pull` / `git push` keepalive
- `rsync` to backup storage
- log rotation
- TLS cert refresh
- health-check pings
- anything where a regex or a 5-line shell script is the obvious right answer

---

## Tool categories (`~/tools/` — the shell glue)

I have ~50 scripts in `~/tools/` that hermes-agent's crons (and my interactive Claude Code sessions) shell out to. Most are project-specific and stay private. The *categories* they fall into:

| Bucket | What's in it (no specifics) |
|---|---|
| **Civic-tech submitters** | Wrappers around city / county / state public service portals — 311 systems, public-records request portals, online complaint forms |
| **Personal-admin watchers** | Poll-and-diff scripts for various external systems where state changes matter (status pages, queue positions, document workflows) |
| **Communication helpers** | Templating + send wrappers for email, Telegram, SMS, fax. Bounce-checking and dry-run modes are standard |
| **Browser / web automation glue** | Cookie extraction (`cookies-txt`), session-aware curl wrappers, headless-browser launchers for things that need a real browser context |
| **Backup + sync** | rclone/rsync wrappers for R2, Drive, local NAS; verification scripts that confirm artifacts landed |
| **Content readers** | Paywall-aware fetchers, transcript pullers, social-feed scrapers (read-only) |
| **Document workflow** | PDF fill+sign helpers, Lob/PostGrid physical-mail senders, DocuSeal automation |
| **Beads + Asana glue** | CLI shortcuts on top of `bd` and the Asana MCP; idempotent dedup-by-fingerprint patterns |
| **VPS / remote diagnostics** | SSH-into-Mac-mini-from-laptop tools (see `tools/hermes-doctor.sh` in this repo as the published example) |

**The published `tools/` directory here intentionally contains just one script** (`hermes-doctor.sh`). Everything else is too case-specific to publish without rewriting from scratch. If a particular tool feels generic enough that it deserves a public sibling, I'll spin it out as its own repo.

---

## Skill usage (which `~/.claude/skills/` get exercised unattended)

Hermes shares `~/.claude/` with my laptop. The full skill catalog lives in [claude-code-starter](https://github.com/barkleesanders/claude-code-starter). Unattended crons skew toward these categories:

| Skill family | Used for in unattended context | Lives in |
|---|---|---|
| **Engineering** — `/carmack`, `/debug`, `/ship`, `/git-safety`, `/git-preflight` | Scheduled code reviews, CI failure triage, post-deploy verification | [claude-code-starter](https://github.com/barkleesanders/claude-code-starter) |
| **Tracking** — `bd` (beads), Asana MCP | Auto-close stale issues, auto-create issues from watcher diffs, EOD digest assembly | [claude-code-starter](https://github.com/barkleesanders/claude-code-starter) |
| **Communication** — `gogcli-google` (Gmail/Drive/Calendar), Telegram via OpenClaw delivery | Send digests, fetch new email, create calendar events from inbound signals | [claude-code-starter](https://github.com/barkleesanders/claude-code-starter) |
| **Civic-tech** — `sf311`, `sf-records-request`, `doge-service` | Public-records request lifecycle automation, civic-issue triage | [claude-code-starter](https://github.com/barkleesanders/claude-code-starter) |
| **Browser** — `chrome-cdp`, `agent-browser`, computer-use MCP | Logged-in browser work, headless scraping, screenshot capture | [claude-code-starter](https://github.com/barkleesanders/claude-code-starter) |
| **Content & docs** — `every-style-editor`, `copy-editing`, `magazine`, `html-report` | Auto-render digests as readable HTML, edit drafts before delivery | [claude-code-starter](https://github.com/barkleesanders/claude-code-starter) |
| **Reverse-engineering** — `/ghidra` | Triage binaries (browser-extension RE, unknown installer audits) — rare in unattended, common in interactive | [claude-code-starter](https://github.com/barkleesanders/claude-code-starter) |
| **Operational** — `taskmaster` stop-hook, `backup-config`, `token-usage` | Session integrity, automated config backups, cost tracking | [claude-code-starter](https://github.com/barkleesanders/claude-code-starter) |

The two layers (interactive on laptop, unattended on Mac mini) share the same skill files because `~/.claude/` is identical on both hosts. A skill I write at my laptop is available to the next OpenClaw cron run that fires.

---

## What I deliberately don't run on this setup

Calling these out so the boundaries are clear:

| Not here | Why |
|---|---|
| Anything that moves money or executes trades | Hard rule — no agent has authority over financial transactions on my behalf |
| Auto-replying to client / case-related email | Always human-in-the-loop; hermes can draft, never send to outside parties |
| Production deploys without `/ship` gates | `/carmack` is forbidden from `wrangler deploy` etc. — it builds and commits, then I (or a manual `/ship`) push |
| Anything that touches a real person's medical, legal, or financial records | Stays in private interactive sessions; never on a cron |
| Auto-posting to social media | Drafts only; I review and post manually |
| Mass cold email | Drafts only |

---

## Sizing

- **OpenClaw crons**: ~15–25 active jobs across the buckets above, with another ~10 paused / seasonal
- **launchd timers**: ~20 deterministic-shell jobs
- **`~/tools/` scripts**: ~50, most private
- **Skills**: see [claude-code-starter's skill list](https://github.com/barkleesanders/claude-code-starter#skills-45) (~50+, shared with interactive use)
- **Token budget**: low-tens-of-dollars per day for the unattended half; the interactive half is the larger spend

These numbers shift week to week as I add/retire jobs. Treat as order-of-magnitude.

---

## Related

- [openclaw/cron-examples.md](./openclaw/cron-examples.md) — three concrete sanitized cron patterns
- [launchd/README.md](./launchd/README.md) — when to use launchd instead
- [hermes/README.md](./hermes/README.md) — what `~/.hermes/` looks like
- [claude-code-starter](https://github.com/barkleesanders/claude-code-starter) — the skills and agents this setup invokes
- [OpenClawBS](https://github.com/barkleesanders/OpenClawBS) — the generic Mac mini scheduling reference architecture
