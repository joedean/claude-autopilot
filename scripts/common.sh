#!/bin/bash
# common.sh — Shared functions and variables for claude-autopilot scripts
# Source this at the top of each script: . "$(dirname "$0")/common.sh"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# --- Trim whitespace from a string ---
# Usage: trimmed=$(trim_whitespace "  hello world  ")
trim_whitespace() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# --- Log a warning without aborting (replacement for || true) ---
# Usage: try_cmd git push origin main
try_cmd() {
    "$@" 2>/dev/null || log_warn "'$*' failed (exit $?)"
}

# --- Log a warning message ---
# Usage: log_warn "something went wrong"
log_warn() {
    echo -e "${YELLOW}  WARN: $1${NC}" >&2
}

# --- Describe recent changes from git state ---
# Returns a short description based on Claude's commits or staged files.
# Usage: desc=$(describe_changes "$prev_head")
describe_changes() {
    local prev_head="$1"
    local desc=""

    # Check if new commits were made since prev_head
    if [ -n "$prev_head" ] && [ "$(git rev-parse HEAD 2>/dev/null)" != "$prev_head" ]; then
        desc=$(git log --format='%s' -1 2>/dev/null)
    fi

    # Fall back to describing staged changes
    if [ -z "$desc" ]; then
        local changed
        changed=$(git diff --cached --name-only 2>/dev/null | head -5)
        if [ -n "$changed" ]; then
            local count first_file
            count=$(echo "$changed" | wc -l | tr -d ' ')
            first_file=$(echo "$changed" | head -1)
            desc="updates $(basename "$first_file" 2>/dev/null)"
            if [ "$count" -gt 1 ]; then
                desc="$desc (+$((count - 1)) more)"
            fi
        fi
    fi

    echo "$desc"
}
