#!/bin/bash
# github-bridge.sh — Polls a GitHub issue for new comments and feeds them to Claude Code
# This is your "command channel" — comment on the issue from your phone,
# Claude Code picks it up, executes, and replies.
#
# Usage: ./github-bridge.sh <owner/repo> <issue_number> [project_dir] [poll_interval]
#   owner/repo:     e.g., "joesmith/my-project"
#   issue_number:   the GitHub issue to watch
#   project_dir:    default current directory
#   poll_interval:  seconds between polls, default 30

set -e

REPO=${1:?"Usage: ./github-bridge.sh <owner/repo> <issue_number> [project_dir] [poll_interval]"}
ISSUE_NUMBER=${2:?"Usage: ./github-bridge.sh <owner/repo> <issue_number> [project_dir] [poll_interval]"}
PROJECT_DIR=${3:-$(pwd)}
POLL_INTERVAL=${4:-30}

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# Track the last processed comment ID to avoid duplicates
LAST_COMMENT_ID=""
STATE_FILE="$PROJECT_DIR/.github-bridge-state"
ACTIVITY_FILE="$PROJECT_DIR/activity.md"
BRIDGE_LOG="$PROJECT_DIR/.github-bridge.log"

# Load last processed comment ID if state file exists
if [ -f "$STATE_FILE" ]; then
    LAST_COMMENT_ID=$(cat "$STATE_FILE")
fi

cd "$PROJECT_DIR"

# Marker prefix used to identify bridge responses (avoids processing our own replies)
BRIDGE_MARKER="<!-- claude-bridge-response -->"

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     GitHub Command Channel Active            ║${NC}"
echo -e "${GREEN}║  Repo: $(printf '%-37s' "$REPO")║${NC}"
echo -e "${GREEN}║  Issue: #$(printf '%-35s' "$ISSUE_NUMBER")║${NC}"
echo -e "${GREEN}║  Polling every ${POLL_INTERVAL}s                       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo -e "${DIM}Comment on issue #$ISSUE_NUMBER to send commands to Claude Code${NC}"
echo -e "${DIM}Special commands: STATUS, STOP, BRANCH, PR, RALPH, TEAM, SDLC${NC}"

# Post initial status comment
gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "${BRIDGE_MARKER}
🤖 **Claude Code bridge is now active.**

I'm watching this issue for commands. Comment here and I'll execute your instructions.

**Special commands:**
- \`STATUS\` — report git status and recent activity
- \`STOP\` — gracefully stop the bridge
- \`BRANCH feature-name\` — create and switch to a new branch
- \`PR\` — create a pull request from current branch
- \`RALPH 20\` — switch to autonomous Ralph mode for N iterations
- \`TEAM <description>\` — spawn an Agent Team (parallel, 3-5 agents coordinate)
- \`SDLC <feature>\` — run full 6-agent SDLC pipeline (product→architect→code→test→security→perf)

**Current state:** $(git branch --show-current 2>/dev/null || echo 'no branch') | $(git log --oneline -1 2>/dev/null || echo 'no commits')

**Agent Teams enabled:** ✅ (teammates spawn as tmux panes)" 2>/dev/null || true

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$BRIDGE_LOG"
}

process_command() {
    local COMMENT_BODY="$1"
    local COMMENT_AUTHOR="$2"
    local COMMENT_ID="$3"

    # Trim whitespace
    COMMENT_BODY=$(echo "$COMMENT_BODY" | xargs)

    echo -e "\n${CYAN}━━━ New command from @$COMMENT_AUTHOR ━━━${NC}"
    echo -e "${CYAN}$COMMENT_BODY${NC}"
    log "Processing command from @$COMMENT_AUTHOR: $COMMENT_BODY"

    # --- Special Commands ---

    # STATUS
    if [[ "${COMMENT_BODY^^}" == "STATUS" ]]; then
        STATUS_MSG="📊 **Status Report**

**Branch:** \`$(git branch --show-current 2>/dev/null)\`
**Last commit:** \`$(git log --oneline -1 2>/dev/null)\`
**Recent changes:**
\`\`\`
$(git log --oneline -5 2>/dev/null || echo 'none')
\`\`\`
**Modified files:**
\`\`\`
$(git status --short 2>/dev/null || echo 'clean')
\`\`\`"
        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "${BRIDGE_MARKER}
$STATUS_MSG"
        return
    fi

    # STOP
    if [[ "${COMMENT_BODY^^}" == "STOP" ]]; then
        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "${BRIDGE_MARKER}
🛑 **Bridge stopping.** Final state: \`$(git branch --show-current)\` — \`$(git log --oneline -1 2>/dev/null)\`"
        echo -e "${RED}Stop command received. Exiting.${NC}"
        exit 0
    fi

    # BRANCH <name>
    if [[ "${COMMENT_BODY^^}" == BRANCH\ * ]]; then
        BRANCH_NAME=$(echo "$COMMENT_BODY" | awk '{print $2}')
        git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME" 2>/dev/null
        git push -u origin "$BRANCH_NAME" 2>/dev/null || true
        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "${BRIDGE_MARKER}
🌿 Switched to branch \`$BRANCH_NAME\`"
        return
    fi

    # PR
    if [[ "${COMMENT_BODY^^}" == "PR" ]]; then
        CURRENT_BRANCH=$(git branch --show-current)
        PR_URL=$(gh pr create -R "$REPO" \
            --title "Claude Code: changes on $CURRENT_BRANCH" \
            --body "Automated PR from Claude Code interactive session.

## Recent commits
$(git log --oneline main..$CURRENT_BRANCH 2>/dev/null || git log --oneline -10)" \
            2>&1) || PR_URL="Failed to create PR: $PR_URL"
        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "${BRIDGE_MARKER}
📝 **Pull Request:** $PR_URL"
        return
    fi

    # RALPH <n>
    if [[ "${COMMENT_BODY^^}" == RALPH\ * ]]; then
        RALPH_ITERS=$(echo "$COMMENT_BODY" | awk '{print $2}')
        RALPH_ITERS=${RALPH_ITERS:-20}
        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "${BRIDGE_MARKER}
🔄 **Switching to Ralph mode** for $RALPH_ITERS iterations. Bridge will pause. Check \`activity.md\` for progress."

        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        "$SCRIPT_DIR/ralph.sh" "$RALPH_ITERS" "$PROJECT_DIR"

        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "${BRIDGE_MARKER}
✅ **Ralph loop finished.** Bridge resuming. Check the latest commits for results."
        return
    fi

    # TEAM <description>
    # Spawns an agent team with your 6 SDLC roles
    if [[ "${COMMENT_BODY^^}" == TEAM\ * ]]; then
        TEAM_TASK=$(echo "$COMMENT_BODY" | sed 's/^[Tt][Ee][Aa][Mm] //')

        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "${BRIDGE_MARKER}
🤝 **Spawning Agent Team** for: _${TEAM_TASK}_

Teammates will coordinate via shared task list and messaging.
Roles: product-owner, solution-architect, clean-code-architect, performance-optimizer, security-hardening-architect, customer-value-qa

I'll post results when the team finishes. Check tmux panes on the server for live progress."

        # React with team emoji
        gh api "repos/$REPO/issues/comments/$COMMENT_ID/reactions" \
            -f content='rocket' --silent 2>/dev/null || true

        # Run Claude Code with team spawn instructions
        # The lead session coordinates; teammates spawn as tmux panes
        OUTPUT=$(claude -p "You are the team lead for this project in $(pwd).
Read CLAUDE.md for the agent role definitions and project context.
Read prd.md for current task status.

YOUR MISSION: ${TEAM_TASK}

INSTRUCTIONS:
1. Create an agent team for this project
2. Break the mission into tasks with clear ownership boundaries
3. Spawn teammates based on the roles defined in CLAUDE.md:
   - solution-architect: designs the approach, defines file boundaries
   - clean-code-architect: implements the core code
   - customer-value-qa: writes tests and validates
   - security-hardening-architect: reviews for security issues
   - performance-optimizer: reviews for performance issues
   Only spawn the roles that are relevant to this mission (typically 3-4).
4. Use delegate mode — coordinate and synthesize, don't implement yourself
5. Ensure each teammate works on different files to avoid conflicts
6. When all tasks are complete:
   - Git add and commit all changes
   - Git push to the current branch
   - Shut down all teammates
   - Clean up the team
   - Summarize what was accomplished

Current branch: $(git branch --show-current 2>/dev/null)
Git status: $(git status --short 2>/dev/null)" \
            --output-format text \
            --max-turns 100 \
            2>&1) || true

        # Push any remaining changes
        git add -A 2>/dev/null || true
        git commit -m "agent-team: ${TEAM_TASK}" 2>/dev/null || true
        git push 2>/dev/null || true

        # Truncate output for GitHub comment
        TRUNCATED_OUTPUT=$(echo "$OUTPUT" | tail -80)
        if [ ${#OUTPUT} -gt 6000 ]; then
            TRUNCATED_OUTPUT="_(output truncated, showing last 80 lines)_

$TRUNCATED_OUTPUT"
        fi

        # Post results
        REPLY="${BRIDGE_MARKER}
🤝 **Agent Team completed**

**Mission:** ${TEAM_TASK}
**Branch:** \`$(git branch --show-current)\`
**Latest commits:**
\`\`\`
$(git log --oneline -10 2>/dev/null)
\`\`\`

<details>
<summary>Team lead output</summary>

\`\`\`
$TRUNCATED_OUTPUT
\`\`\`
</details>"

        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "$REPLY" 2>/dev/null || true

        # Log to activity
        echo -e "\n---\n### Agent Team — $(date '+%Y-%m-%d %H:%M:%S')" >> "$ACTIVITY_FILE"
        echo "**Mission:** $TEAM_TASK" >> "$ACTIVITY_FILE"
        echo "**Commits:**" >> "$ACTIVITY_FILE"
        git log --oneline -10 2>/dev/null >> "$ACTIVITY_FILE"

        echo -e "${GREEN}  ✅ Agent team completed${NC}"
        return
    fi

    # SDLC <description>
    # Full SDLC pipeline: product-owner → architect → implement → test → security → optimize
    if [[ "${COMMENT_BODY^^}" == SDLC\ * ]]; then
        SDLC_TASK=$(echo "$COMMENT_BODY" | sed 's/^[Ss][Dd][Ll][Cc] //')

        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "${BRIDGE_MARKER}
🏭 **Full SDLC Pipeline** starting for: _${SDLC_TASK}_

Running your 6-agent pipeline sequentially:
1. 📋 product-owner → requirements & acceptance criteria
2. 🏗️ solution-architect → technical design
3. 💻 clean-code-architect → implementation
4. 🧪 customer-value-qa → testing
5. 🔒 security-hardening-architect → security review
6. ⚡ performance-optimizer → performance review

This will take a while. I'll post results when complete."

        gh api "repos/$REPO/issues/comments/$COMMENT_ID/reactions" \
            -f content='eyes' --silent 2>/dev/null || true

        OUTPUT=$(claude -p "You are the team lead running a full SDLC pipeline in $(pwd).
Read CLAUDE.md for role definitions and project context.

FEATURE REQUEST: ${SDLC_TASK}

Run the complete SDLC pipeline by spawning an agent team:

1. First, spawn a product-owner teammate to:
   - Analyze the feature request
   - Write clear user stories and acceptance criteria
   - Update prd.md with new tasks
   - Message findings to the team lead

2. After product-owner finishes, spawn a solution-architect teammate to:
   - Read the product-owner's requirements
   - Design the technical approach
   - Define file boundaries for implementation
   - Message the architecture plan to the team lead

3. Then spawn clean-code-architect and customer-value-qa IN PARALLEL:
   - clean-code-architect implements based on the architecture plan
   - customer-value-qa writes tests based on acceptance criteria
   - They should own different files (src/ vs tests/)

4. After implementation, spawn security-hardening-architect and
   performance-optimizer IN PARALLEL to review the code

5. Synthesize all findings, apply any critical fixes, commit and push.

Use delegate mode. Coordinate, don't implement. Each teammate commits
with a role prefix like [clean-code] or [security].

Current branch: $(git branch --show-current 2>/dev/null)" \
            --output-format text \
            --max-turns 150 \
            2>&1) || true

        git add -A 2>/dev/null || true
        git commit -m "sdlc-pipeline: ${SDLC_TASK}" 2>/dev/null || true
        git push 2>/dev/null || true

        TRUNCATED_OUTPUT=$(echo "$OUTPUT" | tail -80)
        if [ ${#OUTPUT} -gt 6000 ]; then
            TRUNCATED_OUTPUT="_(truncated)_

$TRUNCATED_OUTPUT"
        fi

        REPLY="${BRIDGE_MARKER}
🏭 **SDLC Pipeline completed**

**Feature:** ${SDLC_TASK}
**Branch:** \`$(git branch --show-current)\`
**Commits:**
\`\`\`
$(git log --oneline -15 2>/dev/null)
\`\`\`

<details>
<summary>Pipeline output</summary>

\`\`\`
$TRUNCATED_OUTPUT
\`\`\`
</details>"

        gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "$REPLY" 2>/dev/null || true

        echo -e "\n---\n### SDLC Pipeline — $(date '+%Y-%m-%d %H:%M:%S')" >> "$ACTIVITY_FILE"
        echo "**Feature:** $SDLC_TASK" >> "$ACTIVITY_FILE"
        git log --oneline -15 2>/dev/null >> "$ACTIVITY_FILE"

        echo -e "${GREEN}  ✅ SDLC pipeline completed${NC}"
        return
    fi

    # --- Normal task: feed to Claude Code ---
    echo -e "${YELLOW}  Executing with Claude Code...${NC}"

    # React to the comment to show we're working on it
    # (GitHub API - add 👀 reaction)
    gh api "repos/$REPO/issues/comments/$COMMENT_ID/reactions" \
        -f content='eyes' --silent 2>/dev/null || true

    # Run Claude Code with the command
    OUTPUT=$(claude -p "You are working on the project in $(pwd).

TASK FROM THE DEVELOPER (via GitHub issue comment):
$COMMENT_BODY

Instructions:
- Execute the task described above
- Make the necessary code changes
- Run any relevant tests or linting
- Git add and commit your changes with a descriptive message
- Provide a brief summary of what you did

Current git status:
$(git status --short 2>/dev/null)

Current branch: $(git branch --show-current 2>/dev/null)
Recent commits: $(git log --oneline -5 2>/dev/null)" \
        --output-format text \
        --max-turns 30 \
        2>&1) || true

    # Push changes
    git push 2>/dev/null || true

    # Truncate output for GitHub comment (max ~60k chars for GH comments)
    TRUNCATED_OUTPUT=$(echo "$OUTPUT" | tail -100)
    if [ ${#OUTPUT} -gt 6000 ]; then
        TRUNCATED_OUTPUT="_(output truncated, showing last 100 lines)_

$TRUNCATED_OUTPUT"
    fi

    # React with checkmark
    gh api "repos/$REPO/issues/comments/$COMMENT_ID/reactions" \
        -f content='rocket' --silent 2>/dev/null || true

    # Post result back to the issue
    REPLY="${BRIDGE_MARKER}
✅ **Task completed**

**Branch:** \`$(git branch --show-current)\`
**Latest commit:** \`$(git log --oneline -1 2>/dev/null)\`

<details>
<summary>Claude Code output</summary>

\`\`\`
$TRUNCATED_OUTPUT
\`\`\`
</details>"

    gh issue comment "$ISSUE_NUMBER" -R "$REPO" -b "$REPLY" 2>/dev/null || true

    # Log to activity file
    echo -e "\n---\n### GitHub Command — $(date '+%Y-%m-%d %H:%M:%S')" >> "$ACTIVITY_FILE"
    echo "**From:** @$COMMENT_AUTHOR" >> "$ACTIVITY_FILE"
    echo "**Command:** $COMMENT_BODY" >> "$ACTIVITY_FILE"
    echo "**Commit:** $(git log --oneline -1 2>/dev/null)" >> "$ACTIVITY_FILE"

    echo -e "${GREEN}  ✅ Task completed and posted to GitHub${NC}"
}

# --- Main polling loop ---
while true; do
    # Fetch comments on the issue, ordered by creation date
    COMMENTS=$(gh api "repos/$REPO/issues/$ISSUE_NUMBER/comments?sort=created&direction=desc&per_page=5" \
        --jq '.[] | {id: .id, body: .body, user: .user.login, created: .created_at}' \
        2>/dev/null) || {
        echo -e "${RED}  Failed to fetch comments. Retrying in ${POLL_INTERVAL}s...${NC}"
        sleep "$POLL_INTERVAL"
        continue
    }

    # Get the latest comment
    LATEST_ID=$(echo "$COMMENTS" | jq -r '.id' | head -1)
    LATEST_AUTHOR=$(echo "$COMMENTS" | jq -r '.user' | head -1)
    LATEST_BODY=$(echo "$COMMENTS" | jq -r '.body' | head -1)

    # Skip if no new comments, if it's a bridge response (has our marker), or already processed
    if [ -n "$LATEST_ID" ] && \
       [ "$LATEST_ID" != "$LAST_COMMENT_ID" ] && \
       [[ "$LATEST_BODY" != *"$BRIDGE_MARKER"* ]] && \
       [ -n "$LATEST_BODY" ]; then

        # Process the command
        process_command "$LATEST_BODY" "$LATEST_AUTHOR" "$LATEST_ID"

        # Update state
        LAST_COMMENT_ID="$LATEST_ID"
        echo "$LAST_COMMENT_ID" > "$STATE_FILE"
    else
        echo -ne "${DIM}\r  Polling... $(date '+%H:%M:%S') — waiting for commands${NC}"
    fi

    sleep "$POLL_INTERVAL"
done
