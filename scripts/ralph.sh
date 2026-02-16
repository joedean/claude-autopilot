#!/bin/bash
# ralph.sh — Autonomous Claude Code loop with fresh context per iteration
# Based on the Ralph Wiggum technique by Geoffrey Huntley
# Uses fresh context windows (not the plugin approach) to avoid context bloat
#
# Usage: ./ralph.sh [max_iterations] [project_dir]
#   max_iterations: default 20
#   project_dir: default current directory

set -e

# Load shared functions and color variables
. "$(dirname "$0")/common.sh"

MAX_ITERATIONS=${1:-20}
PROJECT_DIR=${2:-$(pwd)}
PROMPT_FILE="$PROJECT_DIR/PROMPT.md"
ACTIVITY_FILE="$PROJECT_DIR/activity.md"
COMPLETION_MARKER="<promise>COMPLETE</promise>"

# --- Validation ---
if [ ! -f "$PROMPT_FILE" ]; then
    echo -e "${RED}Error: PROMPT.md not found in $PROJECT_DIR${NC}"
    echo "Create a PROMPT.md with your task instructions first."
    echo "See templates/PROMPT.md for a starting point."
    exit 1
fi

cd "$PROJECT_DIR"

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Ralph Loop Starting                  ║${NC}"
echo -e "${GREEN}║  Max iterations: $(printf '%-25s' "$MAX_ITERATIONS")║${NC}"
echo -e "${GREEN}║  Project: $(printf '%-34s' "$(basename "$PROJECT_DIR")")║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"

ITERATION=0
START_TIME=$(date +%s)

# Build a descriptive commit message from Claude's commits or changed files
# Usage: iter_commit_msg <iteration> <max_iterations> <suffix>
iter_commit_msg() {
    local iter="$1" max="$2" suffix="$3"
    local desc
    desc=$(describe_changes "$PREV_HEAD")

    if [ -n "$desc" ]; then
        echo "Ralph:${iter}/${max}${suffix} - ${desc}"
    else
        echo "Ralph:${iter}/${max}${suffix}"
    fi
}

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    ITER_START=$(date +%s)

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Iteration $ITERATION / $MAX_ITERATIONS — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Log iteration start
    echo -e "\n---\n### Iteration $ITERATION — $(date '+%Y-%m-%d %H:%M:%S')\n" >> "$ACTIVITY_FILE"

    # Snapshot HEAD so we can detect commits Claude makes
    PREV_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "")

    # Run Claude Code with the prompt in a fresh context
    # Using -p (print/headless mode) for non-interactive execution
    # Stream output to terminal via tee so progress is visible in real time
    ITER_OUTPUT_FILE=$(mktemp)
    claude -p "$(cat "$PROMPT_FILE")" \
        --output-format text \
        --max-turns 50 \
        2>&1 | tee "$ITER_OUTPUT_FILE" || true
    OUTPUT=$(cat "$ITER_OUTPUT_FILE")
    rm -f "$ITER_OUTPUT_FILE"

    # Log output summary (first 500 chars)
    echo "**Output summary:**" >> "$ACTIVITY_FILE"
    echo '```' >> "$ACTIVITY_FILE"
    echo "$OUTPUT" | head -50 >> "$ACTIVITY_FILE"
    echo '```' >> "$ACTIVITY_FILE"

    # Check for completion
    if echo "$OUTPUT" | grep -q "$COMPLETION_MARKER"; then
        ELAPSED=$(( $(date +%s) - START_TIME ))
        echo -e "\n${GREEN}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  ✅ COMPLETE after $ITERATION iterations        ${NC}"
        echo -e "${GREEN}║  Total time: $((ELAPSED / 60))m $((ELAPSED % 60))s               ${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"

        echo -e "\n## ✅ COMPLETED — $(date '+%Y-%m-%d %H:%M:%S')" >> "$ACTIVITY_FILE"
        echo "Iterations: $ITERATION | Time: $((ELAPSED / 60))m $((ELAPSED % 60))s" >> "$ACTIVITY_FILE"

        # Auto-commit completion
        git add -A 2>/dev/null || true
        COMMIT_MSG=$(iter_commit_msg "$ITERATION" "$MAX_ITERATIONS" " COMPLETE")
        git commit -m "$COMMIT_MSG" 2>/dev/null || true

        exit 0
    fi

    # Auto-commit after each iteration
    git add -A 2>/dev/null || true
    COMMIT_MSG=$(iter_commit_msg "$ITERATION" "$MAX_ITERATIONS" "")
    git commit -m "$COMMIT_MSG" 2>/dev/null || true
    git push 2>/dev/null || true

    ITER_ELAPSED=$(( $(date +%s) - ITER_START ))
    echo -e "${YELLOW}  Iteration $ITERATION completed in ${ITER_ELAPSED}s${NC}"

    # Brief pause between iterations
    sleep 2
done

# Max iterations reached
ELAPSED=$(( $(date +%s) - START_TIME ))
echo -e "\n${YELLOW}╔══════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  ⚠️  Max iterations ($MAX_ITERATIONS) reached       ${NC}"
echo -e "${YELLOW}║  Total time: $((ELAPSED / 60))m $((ELAPSED % 60))s               ${NC}"
echo -e "${YELLOW}║  Check activity.md for progress              ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}"

echo -e "\n## ⚠️ MAX ITERATIONS REACHED — $(date '+%Y-%m-%d %H:%M:%S')" >> "$ACTIVITY_FILE"
echo "Iterations: $MAX_ITERATIONS | Time: $((ELAPSED / 60))m $((ELAPSED % 60))s" >> "$ACTIVITY_FILE"

git add -A 2>/dev/null || true
COMMIT_MSG=$(iter_commit_msg "$MAX_ITERATIONS" "$MAX_ITERATIONS" " max-reached")
git commit -m "$COMMIT_MSG" 2>/dev/null || true
git push 2>/dev/null || true
