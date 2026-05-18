# OpenClaw cron — sanitized examples

These are the kinds of jobs that earn their LLM cost. Each one is the
**shape** of a real scheduled prompt I run — names, IDs, and case-specific
paths have been stripped.

For the full job schema, see [docs.openclaw.ai](https://docs.openclaw.ai).
For the generic Mac mini scheduling reference, see
[OpenClawBS](https://github.com/barkleesanders/OpenClawBS).

## Format

OpenClaw stores cron jobs in `~/.hermes/cron/jobs.json` (when invoked via
hermes-agent) or `~/.openclaw/cron/jobs.json` (when invoked directly). Each
job is a JSON object; below I use a YAML-ish shorthand for readability —
adapt to JSON when you create them via `openclaw cron add` or the API.

## Pattern 1 — Nightly self-maintenance (5 min, cheap model)

Quiet most nights. Useful when something drifts.

```yaml
name: "Nightly Self-Maintenance"
schedule: "30 23 * * *"          # 23:30 local
deliver: local                     # don't ping the operator
prompt: |
  Lightweight nightly self-maintenance.

  1. Read these files and check for obvious drift:
     - <HOME>/clawd/MEMORY.md
     - <HOME>/clawd/TOOLS.md

  2. Only edit if there's a clear mismatch with the current setup.

  3. If you edited anything, commit only those two files:
     git -C <HOME>/clawd add MEMORY.md TOOLS.md
     git -C <HOME>/clawd commit -m 'nightly: auto-maintenance'

     Never `git add -A` or `git add .`.

  4. Keep the response brief:
     - Nothing changed: reply HEARTBEAT_OK
     - Changes made: one line saying what was cleaned up.
```

**Why this earns its tokens**: "obvious drift" requires comparing two text
files against a moving target (the actual install state). A shell script
would either over-report or under-report. The model only has to be smart
once a week.

## Pattern 2 — End-of-day digest (Telegram-delivered)

```yaml
name: "Daily Done Digest"
schedule: "0 21 * * *"           # 21:00 local
deliver: "telegram:<YOUR_TELEGRAM_CHAT_ID>"
prompt: |
  End-of-day digest. Send ONE concise Telegram message, then print
  exactly NO_REPLY as your final assistant output.

  Goal: useful, not just a list.

  1. Find skills added/updated today:
     find <HOME>/clawd/skills -name SKILL.md -newermt "$(date +%Y-%m-%d)" -type f

  2. Find closed tasks today:
     bd list --status=closed --updated-since 1d | head -30

  3. Skip noisy items (per-run trackers, heartbeat closes,
     duplicate cron-run tasks unless behavior changed).

  4. Format (max 20 lines, Telegram Markdown):

     🌙 *End of Day — <date>*

     🧠 *Improved today*
     • *<skill>* — Improved: <plain English>. Helps: <why it matters>.

     ✅ *Done*
     ✅ *<outcome>* — <proof or why it helps>

     📊 *Activity* — Sessions: N · Tool calls: ~N · Current errors: N

  5. Quiet day (no skills, no meaningful done): send exactly
     "🌙 *<date>* — Quiet day. Nothing notable."

  Send exactly one Telegram message. Final assistant output: NO_REPLY.
```

**Why this earns its tokens**: requires reading multiple changing data
sources (skills/, beads, session logs), filtering noise, and writing
natural-language summaries with judgment about what matters.

## Pattern 3 — On-demand watcher (high-frequency, narrow scope)

```yaml
name: "Issue Tracker Triage"
schedule: "*/15 9-18 * * 1-5"    # every 15 min, business hours, weekdays
deliver: local                     # only alert if something changed
prompt: |
  Check the GitHub issue queue for repo <YOUR_REPO>.

  1. List issues opened or updated in the last 20 minutes via gh:
     gh issue list --repo <YOUR_REPO> --state open --limit 50 \
       --json number,title,updatedAt,labels

  2. For each new or newly-updated issue:
     - Classify as: bug | feature-request | question | spam | dup
     - If dup: comment a link to the original, label "duplicate", close.
     - If spam: label "spam", close.
     - Otherwise: leave it for human triage.

  3. If you took any action, send one Telegram line with what you did.
     Otherwise, print HEARTBEAT_OK.
```

**Why this earns its tokens**: classification + duplicate detection
requires reading issue bodies. A regex-based bot would mislabel everything.

## Don't put these in OpenClaw

| Task | Use instead |
|---|---|
| `git pull` every 5 min | launchd `StartInterval: 300` |
| Rotate logs daily at 4am | launchd `StartCalendarInterval` |
| `curl healthcheck.io/ping` every 1 min | launchd `StartInterval: 60` |
| Restart a stuck systemd service | systemd's own `Restart=on-failure` or launchd `KeepAlive` |
| Backup `~/Documents/` to R2 | launchd + rclone, no LLM in the loop |

If you find yourself paying agent tokens for any of the above, move it to
[../launchd/](../launchd/).

## How to add a job

```bash
# Interactive (preferred for one-offs):
openclaw cron add

# Programmatic (from a JSON file):
openclaw cron import path/to/job.json

# List:
openclaw cron list

# Pause / unpause without deleting:
openclaw cron pause <id>
openclaw cron unpause <id>
```

See `openclaw cron --help` for the full surface.
