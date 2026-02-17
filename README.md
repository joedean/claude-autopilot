# Claude Autopilot: Ralph + GitHub + Agent Teams

A complete setup for running Claude Code on a Digital Ocean Droplet with three modes:

1. **Ralph Mode** — Autonomous bash loop for clear objectives (overnight builds, scaffolding)
2. **GitHub Interactive Mode** — Steer Claude Code via GitHub issue comments from your phone
3. **Agent Teams Mode** — Spawn parallel specialized agents that coordinate and communicate

All three modes are controlled from GitHub issue comments. Your phone is the command interface.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Digital Ocean Droplet                     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              github-bridge.sh (tmux)                   │  │
│  │         Polls GitHub issue every 30s                   │  │
│  │                                                        │  │
│  │  Comment type:        Action:                          │  │
│  │  ─────────────        ───────                          │  │
│  │  "Add retry logic"  → Claude Code single task          │  │
│  │  "RALPH 20"         → Ralph autonomous loop (20 iter)  │  │
│  │  "TEAM Build API"   → Agent Team (3-5 parallel agents) │  │
│  │  "SDLC Add auth"    → Full 6-agent SDLC pipeline       │  │
│  │  "STATUS"           → Git status report                │  │
│  │  "PR"               → Create pull request              │  │
│  │  "BRANCH feat-x"    → Switch branch                    │  │
│  │  "STOP"             → Shut down bridge                 │  │
│  └────────────────────────────────────────────────────────┘  │
│                              │                               │
│       ┌──────────────────────┼───────────────────┐           │
│       ▼                      ▼                   ▼           │
│  ┌──────────┐   ┌────────────────┐   ┌──────────────────┐    │
│  │  Ralph   │   │  Single Claude │   │  Agent Team      │    │
│  │  Loop    │   │  Code task     │   │  (tmux panes)    │    │
│  │          │   │                │   │                  │    │
│  │ Fresh    │   │ Execute +      │   │ Lead ──┬── Arch  │    │
│  │ context  │   │ commit +       │   │        ├── Code  │    │
│  │ each     │   │ reply to       │   │        ├── Test  │    │
│  │ iteration│   │ GitHub         │   │        ├── Sec   │    │
│  │          │   │                │   │        └── Perf  │    │
│  └──────────┘   └────────────────┘   └──────────────────┘    │
└──────────────────────────────────────────────────────────────┘
         │                  │                    │
         └──────────────────┼────────────────────┘
                            ▼
                   ┌─────────────────┐
                   │  GitHub Repo    │ ◄──── You (phone/laptop)
                   │  Issue #42      │       comment to command
                   │  PRs + commits  │
                   └─────────────────┘
```

## Quick Start

Set up a fresh DO Droplet with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/joedean/claude-autopilot/main/scripts/setup-do-droplet.sh | bash
```

This installs all dependencies (tmux, git, Node.js, GitHub CLI, Claude Code), prompts for your Anthropic API key and GitHub auth, and clones the repo to `~/claude-autopilot`.

Then initialize your project and start the bridge:

```bash
# 1. Initialize a project
cd ~/projects/my-app
~/claude-autopilot/scripts/workflow.sh init

# 2. Edit project files
vim CLAUDE.md      # Define agent roles, tech stack, project structure
vim prd.md         # Define tasks and requirements

# 3. Configure authorized users (required — bridge won't start without this)
echo "your-github-username" > .github-bridge-authorized-users

# 4. Start the GitHub bridge
~/claude-autopilot/scripts/workflow.sh interactive youruser/my-app 42

# 5. Comment on issue #42 from your phone!
```

## Integrating into an Existing Project

Already have a project on your Droplet? Run `workflow.sh init` from your project directory:

```bash
cd ~/projects/my-existing-app
~/claude-autopilot/scripts/workflow.sh init
```

This creates the following files (never overwrites existing ones):

| File | Purpose |
|---|---|
| `CLAUDE.md` | Agent role definitions — auto-loaded by all teammates. **Customize this first.** |
| `prd.md` | Product requirements with JSON task list for Ralph |
| `PROMPT.md` | Instructions for each Ralph iteration |
| `activity.md` | Auto-updated log of all work done |
| `.claude/settings.json` | Agent teams enabled, permissions pre-approved for unattended operation |

**What to customize:**

- **CLAUDE.md** — Add your actual tech stack, project structure, build commands, and any project-specific conventions. All teammates read this automatically.
- **prd.md** — Replace the template tasks with your real requirements. Each task needs `"passes": false` in the JSON array.
- **PROMPT.md** — Update the build/test commands to match your project (e.g., `npm test`, `cargo build`, `pytest`).
- **`.github-bridge-authorized-users`** — You must create this file (or set `AUTHORIZED_USERS` env var) before starting the bridge. See [Security](#security).

**Verify each mode works:**

```bash
# Test Ralph (1 iteration)
~/claude-autopilot/scripts/workflow.sh ralph 1

# Test interactive — start bridge, then comment "STATUS" on your issue
~/claude-autopilot/scripts/workflow.sh interactive youruser/my-app 42

# Test agent team — comment "TEAM Write a hello world test"
```

## Critical Setup Notes

1. **Configure authorized users first** — the bridge won't start without
   `.github-bridge-authorized-users` or `AUTHORIZED_USERS` env var.
   See [Security](#security).

2. **Review the permission deny list** — `.claude/settings.json` blocks
   dangerous commands (curl, docker, kill, force push, etc.) by default.
   If your project needs any of these, move them to the allow list deliberately.

3. **Permissions must be generous** — teammates stall on permission prompts
   with nobody to approve. The included settings.json pre-approves common
   operations.

4. **CLAUDE.md is auto-loaded** — all teammates read it automatically.
   Put your tech stack, conventions, and role definitions there.

5. **File ownership matters** — two teammates editing the same file = overwrites.
   The solution-architect defines boundaries at team creation.

6. **tmux is the backend** — set `CLAUDE_CODE_SPAWN_BACKEND=tmux` (already
   configured). Each teammate gets its own pane. SSH in and use
   `tmux list-panes` to see them.

## Droplet Management

```bash
# Check what's running
~/claude-autopilot/scripts/workflow.sh status

# Attach to see live output
tmux attach -t interactive-session

# Detach without stopping: Ctrl+b, then d

# Stop everything
~/claude-autopilot/scripts/workflow.sh stop all

# View agent team panes (while a team is running)
tmux list-panes
tmux select-pane -t 1   # switch to pane 1

# Monitor activity
tail -f activity.md
git log --oneline -20
```

## The Three Modes

### Mode 1: Single Task (default)

Just comment normally on the issue. Claude Code executes your instruction,
commits, pushes, and replies with results.

```
Comment: "Add error handling to all API routes"
→ Claude Code runs, commits, replies with diff summary
```

### Mode 2: Ralph (autonomous loop)

For grinding through a PRD overnight. Fresh context each iteration.

```
Comment: "RALPH 20"
→ Runs 20 iterations of the Ralph loop
→ Each iteration: pick next task from prd.md, implement, verify, commit
→ Posts summary when done
```

### Mode 3: Agent Teams (parallel specialists)

Spawn multiple Claude Code instances that coordinate via shared task list
and messaging. Each agent gets its own tmux pane and context window.

**TEAM** — Quick parallel team for a specific task:
```
Comment: "TEAM Build the REST API for user management with full CRUD,
         validation, and error handling"
→ Spawns solution-architect, clean-code-architect, customer-value-qa
→ They coordinate, each working on different files
→ Posts combined results when done
```

**SDLC** — Full 6-agent pipeline (your specialized roles):
```
Comment: "SDLC Add JWT authentication with refresh tokens"
→ Phase 1: product-owner writes requirements
→ Phase 2: solution-architect designs approach
→ Phase 3: clean-code-architect + customer-value-qa (parallel)
→ Phase 4: security-hardening + performance-optimizer (parallel)
→ Posts full pipeline results
```

## When to Use Which Mode

| Situation | Mode | Why |
|---|---|---|
| Quick fix or small task | Single task | Low overhead, fast |
| Clear PRD, many tasks, unattended | Ralph | Sequential, fresh context each loop |
| Parallelizable work (API + UI + tests) | TEAM | Agents coordinate, 3-5x faster |
| New feature end-to-end | SDLC | Full pipeline with quality gates |
| Bug investigation | TEAM | Competing hypotheses, agents debate |
| Overnight scaffolding | Ralph | Set and forget |
| Iterative refinement from phone | Single task | You steer, Claude executes |

## Security

### Authorized Users (required)

The GitHub bridge enforces comment-author authorization. **The bridge will refuse to start** if no authorized users are configured. This prevents arbitrary GitHub users from executing commands on your Droplet.

Configure authorized users with **one** of these methods:

**Option 1: File (recommended)** — create `.github-bridge-authorized-users` in your project directory:

```
# One GitHub username per line. Lines starting with # are comments.
your-github-username
trusted-coworker
```

**Option 2: Environment variable** — comma-separated GitHub usernames:

```bash
AUTHORIZED_USERS=your-github-username,trusted-coworker \
  ~/claude-autopilot/scripts/workflow.sh interactive youruser/my-app 42
```

Comments from unauthorized users are silently rejected and logged. The bridge startup banner displays which users are authorized.

### Permission Deny List

`.claude/settings.json` includes a deny list that blocks dangerous operations from being run by Claude Code, even in unattended mode:

| Category | Blocked commands |
|---|---|
| **Destructive filesystem** | `sudo`, `chmod 777`, `rm -rf /`, `rm -rf /*`, `rm -rf ~`, `rm -rf .` |
| **Destructive git** | `git push --force`, `git push --force-with-lease`, `git push origin main*`, `git push origin master*`, `git reset --hard` |
| **GitHub credential/admin** | `gh auth`, `gh repo delete`, `gh secret` |
| **Arbitrary code execution** | `curl`, `python`, `python3`, `pip`, `pip3`, `docker`, `docker compose` |
| **Process management** | `kill`, `pkill`, `killall` |

The `gh` allow list is scoped to specific safe subcommands (`gh issue`, `gh pr`, `gh api repos`, `gh repo clone`, `gh repo view`) rather than a blanket `gh:*`.

Review and customize `.claude/settings.json` for your use case. If your project requires any denied commands (e.g., `docker` for container-based projects), move them to the allow list deliberately.

## All GitHub Comment Commands

| Command | Action |
|---|---|
| _(any text)_ | Execute as a single Claude Code task |
| `STATUS` | Report git status, branch, recent commits |
| `STOP` | Gracefully stop the bridge |
| `BRANCH feature-x` | Create and switch to a new branch |
| `PR` | Create a pull request from current branch |
| `RALPH 20` | Run Ralph loop for 20 iterations |
| `TEAM <description>` | Spawn agent team for parallel work |
| `SDLC <description>` | Run full 6-agent SDLC pipeline |

## Key Files

| File | Purpose |
|---|---|
| `CLAUDE.md` | **Agent role definitions** — auto-loaded by all teammates. Define your tech stack, project structure, and team coordination rules here |
| `prd.md` | Product requirements with JSON task list for Ralph |
| `PROMPT.md` | Instructions for each Ralph iteration |
| `activity.md` | Auto-updated log of all work done |
| `.claude/settings.json` | Agent teams enabled, permissions and deny list for unattended operation |
| `.github-bridge-authorized-users` | **Required.** GitHub usernames allowed to send commands via the bridge |

## File Structure

```
claude-autopilot/
├── scripts/
│   ├── common.sh                # Shared functions and colors (sourced by all scripts)
│   ├── setup-do-droplet.sh      # One-time DO Droplet setup
│   ├── workflow.sh              # Main orchestrator
│   ├── ralph.sh                 # Autonomous bash loop
│   └── github-bridge.sh        # GitHub ↔ Claude Code bridge
├── templates/
│   ├── CLAUDE.md                # Agent role definitions template
│   ├── PROMPT.md                # Ralph loop prompt template
│   ├── activity.md              # Activity log template
│   └── prd-template.md          # PRD template
├── .claude/
│   └── settings.json            # Agent teams + permissions
└── README.md
```

## Agent Teams Details

### How It Works Under the Hood

Agent Teams uses Claude Code's native experimental feature:
- **Team lead** creates a team, defines tasks, spawns teammates
- **Teammates** are full Claude Code instances in tmux panes
- **Shared task list** on disk with states: pending → in_progress → completed
- **Inbox messaging** lets teammates communicate directly
- **Self-claiming** — teammates pick up next available task when done

### Your 6 SDLC Roles (defined in CLAUDE.md)

| Role | Focus | Owns |
|---|---|---|
| product-owner | Requirements, user stories, acceptance criteria | prd.md, docs/ |
| solution-architect | Technical design, API contracts, boundaries | Architecture decisions |
| clean-code-architect | Implementation, SOLID principles | src/ application code |
| performance-optimizer | Profiling, caching, optimization | Performance fixes |
| security-hardening-architect | Vulnerability scanning, auth review | Security fixes |
| customer-value-qa | Tests, validation, coverage | tests/, test fixtures |

### Cost Awareness

Agent Teams uses significantly more tokens than single-agent mode:
- Single task: ~200k tokens
- Team of 3: ~800k tokens
- Team of 5: ~1.2M+ tokens
- Full SDLC pipeline: ~1.5M+ tokens

Use `TEAM` and `SDLC` for work that justifies the cost. Use single tasks
and `RALPH` for routine work.

## Tips

- **Customize CLAUDE.md first** — this is the most important file. Define your
  actual tech stack, project structure, and conventions.
- **Start with single tasks** to verify the bridge works, then try TEAM.
- **Use BRANCH before TEAM/SDLC** — keep experimental work on feature branches.
- **Monitor first TEAM run** — SSH in and watch the tmux panes to verify
  teammates are working correctly.
- **Configure authorized users** — the bridge requires this. Create
  `.github-bridge-authorized-users` or set `AUTHORIZED_USERS` env var.
- **Review `.claude/settings.json`** — the deny list blocks curl, docker,
  python, and other commands by default. Adjust for your project needs.
- **Integrating into an existing project?** — Run `workflow.sh init` from your
  project directory. It only creates files that don't already exist.
- **Add to your PATH** — `export PATH="$HOME/claude-autopilot/scripts:$PATH"`
  in your `.bashrc` so you can run `workflow.sh` from anywhere.
