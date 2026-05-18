# tools/

Small generic glue scripts. Each one is meant to be readable end-to-end in
under a minute and runnable on any Mac mini with the corresponding tool
installed.

| Script | Purpose |
|---|---|
| `hermes-doctor.sh` | Health check for a hermes-agent install. Verifies `~/.hermes/`, log dirs, launchd plist registration, and binary availability. Supports `--remote <host>` to run over ssh. |

## What's NOT here

My actual `~/tools/` directory has ~50 scripts spanning records-request
filing, paid-ads automation, VA claim filing, etc. Those are case-specific
and stay in a private repo behind git-crypt.

This directory only carries the few that are useful as generic patterns
for *anyone* running hermes-agent on a Mac mini.
