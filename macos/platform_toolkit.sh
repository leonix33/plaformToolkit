#!/bin/bash

# ============================================================
#   PLATFORM TOOLKIT INSTALLER FOR MACOS
#   Homebrew-based, user-friendly installation
# ============================================================

set -e

# Parse command line arguments
DRY_RUN=false
FORCE=false
LOG=false
VERBOSE=false
INSTALL_MODE=true  # Default to install mode

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --log)
      LOG=true
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --install)
      INSTALL_MODE=true  # Explicitly set install mode
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--force] [--log] [--verbose] [--install]"
      echo "  --dry-run    Show what would be done without executing"
      echo "  --force      Force reinstall/update all tools"
      echo "  --log        Enable logging to file"
      echo "  --verbose    Enable verbose output"
      echo "  --install    Run in installation mode (default)"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Configuration
BASE_TOOLS="$HOME/Tools"
LOG_FILE="$HOME/platform-toolkit-install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
write_log() {
    local message="$1"
    if [[ "$LOG" == true ]]; then
        echo -e "$message" | tee -a "$LOG_FILE"
    else
        echo -e "$message"
    fi
}

# Function to execute commands conditionally
do_step() {
    local description="$1"
    local command="$2"
    
    if [[ "$DRY_RUN" == true ]]; then
        write_log "[dry-run] $description"
        return 0
    else
        if [[ "$VERBOSE" == true ]]; then
            write_log "$description"
        fi
        eval "$command"
        if [[ $? -eq 0 ]]; then
            write_log "${GREEN}$description completed.${NC}"
            return 0
        else
            write_log "${RED}$description failed.${NC}"
            return 1
        fi
    fi
}

# ============================================================
# 1. Setup Package Managers
# ============================================================

write_log "${GREEN}=== PLATFORM TOOLKIT INSTALL STARTED ===${NC}"
write_log "Dry run: $DRY_RUN"
write_log "Force update: $FORCE"
write_log "Logging: $LOG"
write_log "Verbose: $VERBOSE"

write_log "\n${BLUE}[1] Homebrew Setup${NC}"

# Install/Update Homebrew
setup_homebrew() {
    if ! command -v brew &> /dev/null; then
        do_step "Installing Homebrew..." \
            '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    else
        do_step "Updating Homebrew..." "brew update"
    fi
}

setup_homebrew

# ============================================================
# 2. Additional Package Managers
# ============================================================

write_log "\n${BLUE}[2] Additional Package Managers${NC}"

# Install Conda/Miniconda for Python environment management (FIXED VERSION)
install_conda() {
    if ! command -v conda &> /dev/null; then
        do_step "Installing Miniconda..." \
            'curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-$(uname -m).sh -o /tmp/miniconda.sh && bash /tmp/miniconda.sh -b -p $HOME/miniconda3'
        
        # Fixed conda initialization
        if [[ "$DRY_RUN" != true ]]; then
            write_log "Initializing Conda..."
            export PATH="$HOME/miniconda3/bin:$PATH"
            source "$HOME/miniconda3/etc/profile.d/conda.sh" 2>/dev/null || true
            conda init bash zsh 2>/dev/null || true
            write_log "${GREEN}Conda initialization completed.${NC}"
        else
            write_log "[dry-run] Initializing Conda..."
        fi
    else
        do_step "Updating Conda..." "conda update conda -y"
    fi
}

# Install Node Version Manager (NVM)
install_nvm() {
    if [[ ! -d "$HOME/.nvm" ]]; then
        do_step "Installing NVM..." \
            'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash'
    fi
}

# Install Python Version Manager (pyenv)
install_pyenv() {
    if ! command -v pyenv &> /dev/null; then
        do_step "Installing pyenv..." "brew install pyenv"
    else
        do_step "Updating pyenv..." "brew upgrade pyenv"
    fi
}

# Install additional package managers
install_conda
install_nvm
install_pyenv

# ============================================================
# 3. Install Core Development Tools
# ============================================================

write_log "\n${BLUE}[3] Installing Core Development Tools${NC}"

# Function to install or update Homebrew package
install_or_update_brew() {
    local package="$1"
    
    if brew list "$package" &> /dev/null; then
        if [[ "$FORCE" == true ]]; then
            do_step "Updating $package..." "brew upgrade $package"
        else
            write_log "${GREEN}$package installed/updated.${NC}"
        fi
    else
        do_step "Installing $package..." "brew install $package"
    fi
}

# Core development tools
install_or_update_brew "python@3.12"
install_or_update_brew "git"
install_or_update_brew "azure-cli"
install_or_update_brew "awscli"  # NEW: Added AWS CLI
install_or_update_brew "terraform"
install_or_update_brew "node"
install_or_update_brew "docker"
install_or_update_brew "kubectl"
install_or_update_brew "helm"
install_or_update_brew "jq"
install_or_update_brew "yq"
install_or_update_brew "curl"
install_or_update_brew "wget"

# ============================================================
# 4. Install Development Applications
# ============================================================

write_log "\n${BLUE}[4] Installing Development Applications${NC}"

# Function to install or update Homebrew cask
install_or_update_cask() {
    local package="$1"
    
    if brew list --cask "$package" &> /dev/null; then
        if [[ "$FORCE" == true ]]; then
            do_step "Updating $package..." "brew upgrade --cask $package"
        else
            write_log "${GREEN}$package installed/updated.${NC}"
        fi
    else
        do_step "Installing $package..." "brew install --cask $package"
    fi
}

# Development applications
install_or_update_cask "visual-studio-code"
install_or_update_cask "docker"
install_or_update_cask "postman"
install_or_update_cask "iterm2"

# ============================================================
# 5. Databricks CLI Setup
# ============================================================

write_log "\n${BLUE}[5] Databricks CLI Setup${NC}"

# Install modern Databricks CLI
install_databricks_cli() {
    if ! command -v databricks &> /dev/null; then
        do_step "Installing Databricks CLI..." \
            'curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh'
    else
        write_log "${GREEN}Databricks CLI already installed.${NC}"
    fi
}

install_databricks_cli

# ============================================================
# 6. Install Additional Development Tools
# ============================================================

write_log "\n${BLUE}[6] Installing Additional Development Tools${NC}"

# Additional useful tools
install_or_update_brew "htop"
install_or_update_brew "tree"
install_or_update_brew "tmux"
install_or_update_brew "zsh-autosuggestions"
install_or_update_brew "zsh-syntax-highlighting"
install_or_update_brew "fzf"
install_or_update_brew "ripgrep"
install_or_update_brew "bat"
install_or_update_brew "exa"
install_or_update_brew "fd"

# ============================================================
# 7. Configure Shell Environment
# ============================================================

write_log "\n${BLUE}[7] Configuring Shell Environment${NC}"

# Install Oh My Zsh if not present
install_oh_my_zsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        do_step "Installing Oh My Zsh..." \
            'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    fi
}

install_oh_my_zsh

# Update shell configuration
update_shell_config() {
    local zshrc="$HOME/.zshrc"
    
    if [[ "$DRY_RUN" != true ]]; then
        # Add NVM configuration
        if [[ ! $(grep -q "NVM_DIR" "$zshrc") ]]; then
            cat >> "$zshrc" << 'EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# pyenv Configuration
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"

# Conda Configuration
export PATH="$HOME/miniconda3/bin:$PATH"

# Homebrew Configuration
eval "$(/usr/local/bin/brew shellenv)"

EOF
        fi
        write_log "Shell configuration updated: $zshrc"
    else
        write_log "[dry-run] Shell configuration would be updated"
    fi
}

update_shell_config

# ============================================================
# 8. Generate Version Summary
# ============================================================

write_log "\n${BLUE}[8] Generating Version Summary${NC}"

generate_summary() {
    local VERSION_SUMMARY_FILE="$HOME/platform-toolkit-versions.json"
    
    if [[ "$DRY_RUN" == true ]]; then
        write_log "[dry-run] Version summary would be generated at: $VERSION_SUMMARY_FILE"
        return
    fi
    
    # Get versions of installed tools
    local python_version=$(python3 --version 2>/dev/null || echo "Not installed")
    local git_version=$(git --version 2>/dev/null || echo "Not installed") 
    local node_version=$(node --version 2>/dev/null || echo "Not installed")
    local npm_version=$(npm --version 2>/dev/null || echo "Not installed")
    local az_version=$(az version --output table 2>/dev/null | head -2 | tail -1 | awk '{print $1}' || echo "Not installed")
    local aws_version=$(aws --version 2>/dev/null || echo "Not installed")
    local terraform_version=$(terraform --version 2>/dev/null | head -1 || echo "Not installed")
    local kubectl_version=$(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | awk '{print $2}' || echo "Not installed")
    local helm_version=$(helm version --short 2>/dev/null || echo "Not installed")
    local docker_version=$(docker --version 2>/dev/null || echo "Not installed")
    local databricks_version=$(databricks --version 2>/dev/null || echo "Not installed")

    cat > "$VERSION_SUMMARY_FILE" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "platform": "macOS",
  "tools": {
    "python": "$python_version",
    "git": "$git_version", 
    "node": "$node_version",
    "npm": "$npm_version",
    "azure-cli": "$az_version",
    "aws-cli": "$aws_version",
    "terraform": "$terraform_version",
    "kubectl": "$kubectl_version",
    "helm": "$helm_version",
    "docker": "$docker_version",
    "databricks": "$databricks_version",
    "homebrew": "$(brew --version | head -n1 2>/dev/null)"
  },
  "package_managers": {
    "homebrew": "$(command -v brew &> /dev/null && echo 'installed' || echo 'not installed')",
    "conda": "$(command -v conda &> /dev/null && echo 'installed' || echo 'not installed')",
    "nvm": "$(test -d $HOME/.nvm && echo 'installed' || echo 'not installed')",
    "pyenv": "$(command -v pyenv &> /dev/null && echo 'installed' || echo 'not installed')"
  }
}
EOF

    write_log "${GREEN}Version summary saved: $VERSION_SUMMARY_FILE${NC}"
}

generate_summary

# ============================================================
# Final Status
# ============================================================

write_log "\n${GREEN}=== PLATFORM TOOLKIT INSTALLATION COMPLETED ===${NC}"
write_log "${YELLOW}Note: You may need to restart your terminal or run 'source ~/.zshrc' to activate all tools.${NC}"

if [[ "$LOG" == true ]]; then
    write_log "${BLUE}Installation log saved to: $LOG_FILE${NC}"
fi

exit 0