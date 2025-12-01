#!/bin/bash

# ============================================================
#   PLATFORM TOOLKIT QUICK INSTALLER FOR MACOS
# ============================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INSTALL_DIR="$HOME/PlatformToolkit"
REPO_URL="https://github.com/leonix33/PlatformToolkit-macOS.git"  # Update with your actual repo URL

echo -e "${BLUE}Platform Toolkit for macOS - Quick Installer${NC}"
echo ""

# Check if directory exists
if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}Platform Toolkit is already installed at $INSTALL_DIR${NC}"
    read -p "Do you want to update it? (y/N): " update_choice
    if [[ "$update_choice" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Updating Platform Toolkit...${NC}"
        cd "$INSTALL_DIR"
        git pull origin main
        echo -e "${GREEN}Platform Toolkit updated!${NC}"
    else
        echo "Installation cancelled."
        exit 0
    fi
else
    # Fresh installation
    echo -e "${BLUE}Installing Platform Toolkit to $INSTALL_DIR${NC}"
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Git is required but not installed.${NC}"
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "Please re-run this installer after Xcode Command Line Tools installation completes."
        exit 1
    fi
    
    # Clone the repository
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Make scripts executable
    chmod +x *.sh scripts/*.sh
    
    echo -e "${GREEN}Platform Toolkit installed successfully!${NC}"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Go to the installation directory:"
echo "   cd $INSTALL_DIR"
echo ""
echo "2. Run the toolkit:"
echo "   ./run_toolkit.sh install          # Install all tools"
echo "   ./run_toolkit.sh install --dry-run # Preview installation"
echo "   ./run_toolkit.sh verify           # Verify installation"
echo "   ./run_toolkit.sh help             # Show all options"
echo ""
echo -e "${BLUE}Happy coding! 🚀${NC}"
