#!/bin/bash
# workflow.sh — Main orchestrator for the Claude Autopilot workflow
# Manages tmux sessions for Ralph and Interactive modes
#
# Usage:
#   ./workflow.sh init                              — Initialize project for claude-autopilot
#   ./workflow.sh ralph [iterations] [project_dir]  — Start Ralph in tmux
#   ./workflow.sh interactive <repo> <issue> [dir]  — Start GitHub bridge in tmux
#   ./workflow.sh stop [ralph|interactive|all]      — Stop sessions
#   ./workflow.sh status                            — Show running sessions
#   ./workflow.sh attach [ralph|interactive]        — Attach to a session
#   ./workflow.sh logs [ralph|interactive]          — Tail activity logs

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RALPH_SESSION="ralph-session"
INTERACTIVE_SESSION="interactive-session"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    echo -e "${CYAN}Claude Autopilot${NC}"
    echo ""
    echo "Usage:"
    echo "  $(basename "$0") init                                  — Initialize project"
    echo "  $(basename "$0") ralph [iterations] [project_dir]      — Start autonomous Ralph loop"
    echo "  $(basename "$0") interactive <owner/repo> <issue#> [dir] — Start GitHub bridge"
    echo "  $(basename "$0") stop [ralph|interactive|all]          — Stop sessions"
    echo "  $(basename "$0") status                                — Show running sessions"
    echo "  $(basename "$0") attach [ralph|interactive]            — Attach to tmux session"
    echo "  $(basename "$0") logs [ralph|interactive]              — Tail activity log"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") init"
    echo "  $(basename "$0") ralph 20"
    echo "  $(basename "$0") interactive myuser/myrepo 42"
    echo "  $(basename "$0") stop all"
}

# --- INIT ---
cmd_init() {
    PROJECT_DIR=${1:-$(pwd)}
    echo -e "${GREEN}Initializing claude-autopilot in $PROJECT_DIR${NC}"

    # Create directories
    mkdir -p "$PROJECT_DIR/.claude/commands"
    mkdir -p "$PROJECT_DIR/screenshots"

    # Copy templates if they don't exist
    if [ ! -f "$PROJECT_DIR/PROMPT.md" ]; then
        cp "$SCRIPT_DIR/../templates/PROMPT.md" "$PROJECT_DIR/PROMPT.md"
        echo -e "  ${GREEN}✓${NC} Created PROMPT.md"
    else
        echo -e "  ${YELLOW}⊘${NC} PROMPT.md already exists"
    fi

    if [ ! -f "$PROJECT_DIR/activity.md" ]; then
        cp "$SCRIPT_DIR/../templates/activity.md" "$PROJECT_DIR/activity.md"
        echo -e "  ${GREEN}✓${NC} Created activity.md"
    else
        echo -e "  ${YELLOW}⊘${NC} activity.md already exists"
    fi

    if [ ! -f "$PROJECT_DIR/prd.md" ]; then
        cp "$SCRIPT_DIR/../templates/prd-template.md" "$PROJECT_DIR/prd.md"
        echo -e "  ${GREEN}✓${NC} Created prd.md (edit this with your requirements)"
    else
        echo -e "  ${YELLOW}⊘${NC} prd.md already exists"
    fi

    if [ ! -f "$PROJECT_DIR/.claude/settings.json" ]; then
        cp "$SCRIPT_DIR/../.claude/settings.json" "$PROJECT_DIR/.claude/settings.json"
        echo -e "  ${GREEN}✓${NC} Created .claude/settings.json (agent teams enabled)"
    else
        echo -e "  ${YELLOW}⊘${NC} .claude/settings.json already exists"
    fi

    if [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
        cp "$SCRIPT_DIR/../templates/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
        echo -e "  ${GREEN}✓${NC} Created CLAUDE.md (agent role definitions — customize this!)"
    else
        echo -e "  ${YELLOW}⊘${NC} CLAUDE.md already exists"
    fi

    # Init git if needed
    if [ ! -d "$PROJECT_DIR/.git" ]; then
        cd "$PROJECT_DIR"
        git init
        git add -A
        git commit -m "initial commit: claude-autopilot initialized"
        echo -e "  ${GREEN}✓${NC} Git initialized with initial commit"
    fi

    echo -e "\n${GREEN}Project initialized!${NC}"
    echo -e "Next steps:"
    echo -e "  1. Edit ${CYAN}prd.md${NC} with your project requirements"
    echo -e "  2. Edit ${CYAN}PROMPT.md${NC} to customize the Ralph loop prompt"
    echo -e "  3. Run: ${CYAN}$(basename "$0") ralph 20${NC}"
    echo -e "     Or:  ${CYAN}$(basename "$0") interactive owner/repo ISSUE#${NC}"
}

# --- RALPH ---
cmd_ralph() {
    local ITERATIONS=${1:-20}
    local PROJECT_DIR=${2:-$(pwd)}
    PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

    # Check if already running
    if tmux has-session -t "$RALPH_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}Ralph session already running. Stop it first with: $(basename "$0") stop ralph${NC}"
        exit 1
    fi

    echo -e "${GREEN}Starting Ralph loop in tmux session: $RALPH_SESSION${NC}"
    echo -e "  Iterations: $ITERATIONS"
    echo -e "  Project: $PROJECT_DIR"

    # Create tmux session and run ralph.sh
    tmux new-session -d -s "$RALPH_SESSION" -c "$PROJECT_DIR" \
        "$SCRIPT_DIR/ralph.sh $ITERATIONS $PROJECT_DIR"

    echo -e "\n${GREEN}✅ Ralph is running!${NC}"
    echo -e "  Attach:  ${CYAN}tmux attach -t $RALPH_SESSION${NC}"
    echo -e "  Detach:  ${CYAN}Ctrl+b, then d${NC}"
    echo -e "  Monitor: ${CYAN}tail -f $PROJECT_DIR/activity.md${NC}"
    echo -e "  Stop:    ${CYAN}$(basename "$0") stop ralph${NC}"
}

# --- INTERACTIVE ---
cmd_interactive() {
    local REPO=${1:?"Usage: $(basename "$0") interactive <owner/repo> <issue_number> [project_dir]"}
    local ISSUE=${2:?"Usage: $(basename "$0") interactive <owner/repo> <issue_number> [project_dir]"}
    local PROJECT_DIR=${3:-$(pwd)}
    PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

    # Check if already running
    if tmux has-session -t "$INTERACTIVE_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}Interactive session already running. Stop it first with: $(basename "$0") stop interactive${NC}"
        exit 1
    fi

    echo -e "${GREEN}Starting GitHub bridge in tmux session: $INTERACTIVE_SESSION${NC}"
    echo -e "  Repo: $REPO"
    echo -e "  Issue: #$ISSUE"
    echo -e "  Project: $PROJECT_DIR"

    # Create tmux session and run github-bridge.sh
    tmux new-session -d -s "$INTERACTIVE_SESSION" -c "$PROJECT_DIR" \
        "$SCRIPT_DIR/github-bridge.sh $REPO $ISSUE $PROJECT_DIR"

    echo -e "\n${GREEN}✅ GitHub bridge is active!${NC}"
    echo -e "  Comment on issue #$ISSUE to send commands to Claude Code"
    echo -e "  Attach:  ${CYAN}tmux attach -t $INTERACTIVE_SESSION${NC}"
    echo -e "  Detach:  ${CYAN}Ctrl+b, then d${NC}"
    echo -e "  Stop:    ${CYAN}$(basename "$0") stop interactive${NC}"
}

# --- STOP ---
cmd_stop() {
    local TARGET=${1:-all}

    case $TARGET in
        ralph)
            if tmux has-session -t "$RALPH_SESSION" 2>/dev/null; then
                tmux kill-session -t "$RALPH_SESSION"
                echo -e "${GREEN}✅ Ralph session stopped${NC}"
            else
                echo -e "${YELLOW}Ralph session not running${NC}"
            fi
            ;;
        interactive)
            if tmux has-session -t "$INTERACTIVE_SESSION" 2>/dev/null; then
                tmux kill-session -t "$INTERACTIVE_SESSION"
                echo -e "${GREEN}✅ Interactive session stopped${NC}"
            else
                echo -e "${YELLOW}Interactive session not running${NC}"
            fi
            ;;
        all)
            cmd_stop ralph
            cmd_stop interactive
            ;;
        *)
            echo -e "${RED}Unknown target: $TARGET (use ralph, interactive, or all)${NC}"
            ;;
    esac
}

# --- STATUS ---
cmd_status() {
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            Workflow Status                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"

    # Ralph
    if tmux has-session -t "$RALPH_SESSION" 2>/dev/null; then
        echo -e "\n  ${GREEN}●${NC} Ralph:       ${GREEN}RUNNING${NC} (tmux: $RALPH_SESSION)"
    else
        echo -e "\n  ${RED}○${NC} Ralph:       ${RED}STOPPED${NC}"
    fi

    # Interactive
    if tmux has-session -t "$INTERACTIVE_SESSION" 2>/dev/null; then
        echo -e "  ${GREEN}●${NC} Interactive: ${GREEN}RUNNING${NC} (tmux: $INTERACTIVE_SESSION)"
    else
        echo -e "  ${RED}○${NC} Interactive: ${RED}STOPPED${NC}"
    fi

    # All tmux sessions
    echo -e "\n  ${CYAN}All tmux sessions:${NC}"
    tmux list-sessions 2>/dev/null || echo "    (none)"
    echo ""
}

# --- ATTACH ---
cmd_attach() {
    local TARGET=${1:-ralph}
    case $TARGET in
        ralph)       tmux attach -t "$RALPH_SESSION" ;;
        interactive) tmux attach -t "$INTERACTIVE_SESSION" ;;
        *)           echo -e "${RED}Unknown target: $TARGET${NC}" ;;
    esac
}

# --- LOGS ---
cmd_logs() {
    local PROJECT_DIR=$(pwd)
    if [ -f "$PROJECT_DIR/activity.md" ]; then
        tail -f "$PROJECT_DIR/activity.md"
    else
        echo -e "${RED}No activity.md found in current directory${NC}"
    fi
}

# --- Main dispatcher ---
case ${1:-} in
    init)        shift; cmd_init "$@" ;;
    ralph)       shift; cmd_ralph "$@" ;;
    interactive) shift; cmd_interactive "$@" ;;
    stop)        shift; cmd_stop "$@" ;;
    status)      cmd_status ;;
    attach)      shift; cmd_attach "$@" ;;
    logs)        cmd_logs ;;
    -h|--help|"") usage ;;
    *)           echo -e "${RED}Unknown command: $1${NC}\n"; usage; exit 1 ;;
esac
