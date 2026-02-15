#!/bin/bash
# setup-do-server.sh — One-time setup for Digital Ocean server
# Run this once on a fresh Ubuntu droplet

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Hybrid Claude Code Workflow - Server Setup  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"

# --- System packages ---
echo -e "\n${YELLOW}[1/6] Installing system packages...${NC}"
sudo apt-get update -qq
sudo apt-get install -y -qq tmux git curl jq

# --- Node.js (if not installed) ---
echo -e "\n${YELLOW}[2/6] Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y -qq nodejs
else
    echo "Node.js $(node -v) already installed"
fi

# --- GitHub CLI ---
echo -e "\n${YELLOW}[3/6] Checking GitHub CLI...${NC}"
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq gh
else
    echo "GitHub CLI $(gh --version | head -1) already installed"
fi

# --- Claude Code ---
echo -e "\n${YELLOW}[4/6] Checking Claude Code...${NC}"
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
else
    echo "Claude Code already installed"
fi

# --- API Key ---
echo -e "\n${YELLOW}[5/6] Checking Anthropic API Key...${NC}"
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${RED}ANTHROPIC_API_KEY not set!${NC}"
    read -p "Enter your Anthropic API key: " api_key
    echo "export ANTHROPIC_API_KEY=\"$api_key\"" >> ~/.bashrc
    export ANTHROPIC_API_KEY="$api_key"
    echo "Added to ~/.bashrc"
else
    echo "API key is set"
fi

# --- GitHub Auth ---
echo -e "\n${YELLOW}[6/6] Checking GitHub authentication...${NC}"
if ! gh auth status &> /dev/null 2>&1; then
    echo -e "${YELLOW}GitHub CLI not authenticated. Running gh auth login...${NC}"
    gh auth login
else
    echo "GitHub CLI authenticated"
fi

# --- Configure git ---
echo -e "\n${YELLOW}Configuring git defaults...${NC}"
git config --global init.defaultBranch main 2>/dev/null || true
if [ -z "$(git config --global user.name)" ]; then
    read -p "Git user name: " git_name
    git config --global user.name "$git_name"
fi
if [ -z "$(git config --global user.email)" ]; then
    read -p "Git email: " git_email
    git config --global user.email "$git_email"
fi

# --- Create workspace ---
mkdir -p ~/projects

# --- Make scripts executable ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$SCRIPT_DIR"/*.sh

echo -e "\n${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Setup Complete!                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. cd ~/projects/my-project"
echo -e "  2. $SCRIPT_DIR/workflow.sh init"
echo -e "  3. Edit prd.md with your requirements"
echo -e "  4. $SCRIPT_DIR/workflow.sh ralph 20"
echo -e ""
echo -e "Or for interactive mode:"
echo -e "  $SCRIPT_DIR/workflow.sh interactive owner/repo ISSUE_NUMBER"
