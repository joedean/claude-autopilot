#!/bin/bash
# setup-do-droplet.sh — One-time setup for a Digital Ocean Droplet
# Run this once on a fresh Ubuntu droplet

set -e

# Load shared functions and color variables
. "$(dirname "$0")/common.sh"

REPO_URL="https://github.com/joedean/claude-autopilot.git"
INSTALL_DIR="$HOME/claude-autopilot"

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Claude Autopilot - DO Droplet Setup        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"

# --- System packages ---
echo -e "\n${YELLOW}[1/7] Installing system packages...${NC}"
sudo apt-get update -qq
sudo apt-get install -y -qq tmux git curl jq

# --- Node.js (if not installed) ---
echo -e "\n${YELLOW}[2/7] Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y -qq nodejs
else
    echo "Node.js $(node -v) already installed"
fi

# --- GitHub CLI ---
echo -e "\n${YELLOW}[3/7] Checking GitHub CLI...${NC}"
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
echo -e "\n${YELLOW}[4/7] Checking Claude Code...${NC}"
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
else
    echo "Claude Code already installed"
fi

# --- API Key ---
echo -e "\n${YELLOW}[5/7] Checking Anthropic API Key...${NC}"
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
echo -e "\n${YELLOW}[6/7] Checking GitHub authentication...${NC}"
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

# --- Clone or update repo ---
echo -e "\n${YELLOW}[7/7] Setting up claude-autopilot...${NC}"
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing clone..."
    git -C "$INSTALL_DIR" pull
else
    echo "Cloning claude-autopilot..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# --- Make scripts executable ---
chmod +x "$INSTALL_DIR/scripts/"*.sh

echo -e "\n${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Setup Complete!                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. cd ~/projects/my-project"
echo -e "  2. ~/claude-autopilot/scripts/workflow.sh init"
echo -e "  3. Edit prd.md with your requirements"
echo -e "  4. ~/claude-autopilot/scripts/workflow.sh ralph 20"
echo -e ""
echo -e "Or for interactive mode:"
echo -e "  ~/claude-autopilot/scripts/workflow.sh interactive owner/repo ISSUE_NUMBER"
