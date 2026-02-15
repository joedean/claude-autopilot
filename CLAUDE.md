# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

This is **not an application** — it's an infrastructure toolkit of bash scripts and templates for running Claude Code autonomously on a Digital Ocean Droplet. It provides three execution modes controlled via GitHub issue comments:

1. **Single task** — one-shot Claude Code execution from a comment
2. **Ralph loop** (`ralph.sh`) — autonomous bash loop with fresh context per iteration, driven by a PRD task list
3. **Agent Teams** (`TEAM`/`SDLC` commands) — parallel Claude Code instances coordinated via shared task lists and messaging in tmux panes

## Scripts

All scripts are in `scripts/` and are bash. They use `set -e` and expect `gh` (GitHub CLI), `tmux`, `jq`, and `claude` (Claude Code CLI) to be available.

| Script | Purpose |
|---|---|
| `workflow.sh` | Main orchestrator — `init`, `ralph`, `interactive`, `stop`, `status`, `attach`, `logs` subcommands |
| `github-bridge.sh` | Polls a GitHub issue every 30s for new comments, dispatches to the right mode |
| `ralph.sh` | Autonomous loop: reads `PROMPT.md`, runs `claude -p`, checks for `<promise>COMPLETE</promise>`, auto-commits each iteration |
| `setup-do-droplet.sh` | One-time DO Droplet setup (installs tmux, gh, node, claude-code) |

## Templates

`templates/` contains files that `workflow.sh init` copies into a target project directory (only if they don't already exist):

- `CLAUDE.md` — Agent role definitions (product-owner, solution-architect, clean-code-architect, performance-optimizer, security-hardening-architect, customer-value-qa) and team coordination rules
- `PROMPT.md` — Instructions for each Ralph iteration (read PRD, pick next failing task, implement, verify, commit)
- `prd-template.md` — PRD with a JSON task array where each task has `"passes": false/true`
- `activity.md` — Activity log template

## Key Conventions

- **Ralph completion signal**: The Ralph loop checks for `<promise>COMPLETE</promise>` in Claude's output to know all tasks are done
- **PRD task format**: Tasks in `prd.md` are a JSON array with `"passes": false` — Ralph picks the first failing one
- **tmux session names**: `ralph-session` and `interactive-session` are hardcoded in `workflow.sh`
- **State tracking**: `github-bridge.sh` persists last-processed comment ID in `.github-bridge-state`
- **Activity logging**: Both Ralph and the bridge append to `activity.md` in the project directory
- **Agent Teams env vars**: Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and `CLAUDE_CODE_SPAWN_BACKEND=tmux` (set in `.claude/settings.json`)
- **Git commits**: Ralph auto-commits with `ralph: iteration N of M`; bridge commits with `agent-team: <task>` or `sdlc-pipeline: <task>`

## Command Dispatch (github-bridge.sh)

The bridge parses comment text case-insensitively:
- `STATUS` — git status report
- `STOP` — exits the bridge
- `BRANCH <name>` — creates/switches branch
- `PR` — creates a pull request
- `RALPH <n>` — runs ralph.sh inline (bridge pauses)
- `TEAM <desc>` — spawns agent team via `claude -p` with `--max-turns 100`
- `SDLC <desc>` — runs 6-agent pipeline via `claude -p` with `--max-turns 150`
- Anything else — single Claude Code task via `claude -p` with `--max-turns 30`

## Permissions

`.claude/settings.json` pre-approves common bash commands for unattended operation. Force push to main and `sudo` are denied. This file is copied to target projects during `init`.
