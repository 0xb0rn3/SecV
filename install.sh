#!/usr/bin/env bash
#
# SecV Installation Script v2.2
# Enhanced with universal Linux compatibility and improved dependency management
#
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SECV_BIN="$SCRIPT_DIR/secV"
REQUIREMENTS_FILE="$SCRIPT_DIR/requirements.txt"

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Banner
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   ███████╗███████╗ ██████╗██╗   ██╗                             ║
║   ██╔════╝██╔════╝██╔════╝██║   ██║                             ║
║   ███████╗█████╗  ██║     ██║   ██║                             ║
║   ╚════██║██╔══╝  ██║     ╚██╗ ██╔╝                             ║
║   ███████║███████╗╚██████╗ ╚████╔╝                              ║
║   ╚══════╝╚══════╝ ╚═════╝  ╚═══╝                               ║
║                                                                   ║
║   SecV Installer v2.2 - Universal Linux Compatible               ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}[*] Starting SecV installation...${NC}\n"

# ============================================================================
# Detect System Information
# ============================================================================

echo -e "${YELLOW}[1/8] Detecting system information...${NC}"
DISTRO=$(detect_distro)
echo -e "${GREEN}[✓] Detected distribution: ${DISTRO}${NC}"

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
    echo -e "${GREEN}[✓] Operating system: macOS${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
    echo -e "${GREEN}[✓] Operating system: Linux${NC}"
else
    OS_TYPE="unknown"
    echo -e "${YELLOW}[!] Unknown operating system: $OSTYPE${NC}"
fi
echo

# ============================================================================
# Check Prerequisites
# ============================================================================

echo -e "${YELLOW}[2/8] Checking Python installation...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[!] Python 3 is not installed!${NC}"
    echo -e "${YELLOW}    Installing Python 3...${NC}"
    
    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop|kali)
            sudo apt-get update && sudo apt-get install -y python3 python3-pip
            ;;
        fedora|rhel|centos|rocky|almalinux)
            sudo dnf install -y python3 python3-pip || sudo yum install -y python3 python3-pip
            ;;
        arch|manjaro|endeavouros)
            sudo pacman -Sy --noconfirm python python-pip
            ;;
        opensuse*|suse)
            sudo zypper install -y python3 python3-pip
            ;;
        gentoo)
            sudo emerge -av dev-lang/python
            ;;
        alpine)
            sudo apk add python3 py3-pip
            ;;
        void)
            sudo xbps-install -Sy python3 python3-pip
            ;;
        *)
            echo -e "${RED}[!] Unsupported distribution. Please install Python 3.8+ manually.${NC}"
            exit 1
            ;;
    esac
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    echo -e "${RED}[!] Python 3.8 or later is required (found $PYTHON_VERSION)${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] Python $PYTHON_VERSION found${NC}\n"

# ============================================================================
# Check pip
# ============================================================================

echo -e "${YELLOW}[3/8] Checking pip installation...${NC}"
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}[!] pip3 is not installed!${NC}"
    echo -e "${YELLOW}    Installing pip...${NC}"
    
    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop|kali)
            sudo apt-get install -y python3-pip
            ;;
        fedora|rhel|centos|rocky|almalinux)
            sudo dnf install -y python3-pip || sudo yum install -y python3-pip
            ;;
        arch|manjaro|endeavouros)
            sudo pacman -S --noconfirm python-pip
            ;;
        opensuse*|suse)
            sudo zypper install -y python3-pip
            ;;
        alpine)
            sudo apk add py3-pip
            ;;
        void)
            sudo xbps-install -Sy python3-pip
            ;;
        *)
            python3 -m ensurepip --upgrade 2>/dev/null || true
            ;;
    esac
fi
echo -e "${GREEN}[✓] pip3 found${NC}\n"

# ============================================================================
# Installation Tier Selection
# ============================================================================

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                   ║${NC}"
echo -e "${CYAN}║   Installation Tier Selection                                     ║${NC}"
echo -e "${CYAN}║                                                                   ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Choose your installation tier:${NC}\n"

echo -e "${GREEN}1) Basic${NC} - Core functionality only (~5MB)"
echo -e "   • cmd2, rich (required)"
echo -e "   • TCP connect scanning"
echo -e "   • All modules work with reduced features"
echo -e "   ${BLUE}Best for: Minimal footprint, testing${NC}\n"

echo -e "${GREEN}2) Standard${NC} - Core + scanning tools (~50MB) ${MAGENTA}⭐ Recommended${NC}"
echo -e "   • Basic + scapy, python-nmap"
echo -e "   • SYN scanning (stealth)"
echo -e "   • Nmap integration"
echo -e "   • Full port scanner features"
echo -e "   ${BLUE}Best for: Most users, penetration testing${NC}\n"

echo -e "${GREEN}3) Full${NC} - All features (~100MB)"
echo -e "   • All dependencies from requirements.txt"
echo -e "   • HTTP technology detection"
echo -e "   • Web scraping capabilities"
echo -e "   • DNS operations, SSH, crypto"
echo -e "   • Complete module support"
echo -e "   ${BLUE}Best for: Advanced users, all features${NC}\n"

read -p "Select tier [1-3] (default: 2): " TIER
TIER=${TIER:-2}

case $TIER in
    1)
        TIER_NAME="Basic"
        INSTALL_DEPS="cmd2>=2.4.3 rich>=13.0.0 argcomplete>=3.0.0"
        ;;
    2)
        TIER_NAME="Standard"
        INSTALL_DEPS="cmd2>=2.4.3 rich>=13.0.0 argcomplete>=3.0.0 scapy>=2.5.0 python-nmap>=0.7.1"
        ;;
    3)
        TIER_NAME="Full"
        # Read all dependencies from requirements.txt
        if [ -f "$REQUIREMENTS_FILE" ]; then
            INSTALL_DEPS=$(grep -v '^#' "$REQUIREMENTS_FILE" | grep -v '^$' | tr '\n' ' ')
        else
            echo -e "${RED}[!] requirements.txt not found!${NC}"
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}[!] Invalid selection. Using Standard tier.${NC}"
        TIER=2
        TIER_NAME="Standard"
        INSTALL_DEPS="cmd2>=2.4.3 rich>=13.0.0 argcomplete>=3.0.0 scapy>=2.5.0 python-nmap>=0.7.1"
        ;;
esac

echo -e "\n${GREEN}[✓] Selected: $TIER_NAME tier${NC}\n"

# ============================================================================
# Platform-Specific Dependencies
# ============================================================================

if [ $TIER -ge 2 ]; then
    echo -e "${YELLOW}[4/8] Checking platform-specific dependencies...${NC}"
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        case "$DISTRO" in
            ubuntu|debian|linuxmint|pop|kali)
                if ! dpkg -l | grep -q libpcap-dev; then
                    echo -e "${YELLOW}[i] Scapy requires libpcap-dev on Debian/Ubuntu${NC}"
                    read -p "Install libpcap-dev? (recommended) [Y/n]: " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                        sudo apt-get update && sudo apt-get install -y libpcap-dev
                        echo -e "${GREEN}[✓] libpcap-dev installed${NC}"
                    fi
                fi
                ;;
            fedora|rhel|centos|rocky|almalinux)
                if ! rpm -q libpcap-devel &>/dev/null; then
                    echo -e "${YELLOW}[i] Scapy requires libpcap-devel on RHEL/Fedora${NC}"
                    read -p "Install libpcap-devel? (recommended) [Y/n]: " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                        sudo dnf install -y libpcap-devel || sudo yum install -y libpcap-devel
                        echo -e "${GREEN}[✓] libpcap-devel installed${NC}"
                    fi
                fi
                ;;
            arch|manjaro|endeavouros)
                if ! pacman -Qi libpcap &>/dev/null; then
                    echo -e "${YELLOW}[i] Scapy requires libpcap on Arch${NC}"
                    read -p "Install libpcap? (recommended) [Y/n]: " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                        sudo pacman -S --noconfirm libpcap
                        echo -e "${GREEN}[✓] libpcap installed${NC}"
                    fi
                fi
                ;;
            opensuse*|suse)
                if ! rpm -q libpcap-devel &>/dev/null; then
                    echo -e "${YELLOW}[i] Scapy requires libpcap-devel on openSUSE${NC}"
                    read -p "Install libpcap-devel? (recommended) [Y/n]: " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                        sudo zypper install -y libpcap-devel
                        echo -e "${GREEN}[✓] libpcap-devel installed${NC}"
                    fi
                fi
                ;;
            alpine)
                if ! apk info -e libpcap-dev &>/dev/null; then
                    echo -e "${YELLOW}[i] Scapy requires libpcap-dev on Alpine${NC}"
                    read -p "Install libpcap-dev? (recommended) [Y/n]: " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                        sudo apk add libpcap-dev
                        echo -e "${GREEN}[✓] libpcap-dev installed${NC}"
                    fi
                fi
                ;;
        esac
    elif [[ "$OS_TYPE" == "macos" ]]; then
        echo -e "${GREEN}[✓] macOS - no additional dependencies needed${NC}"
    fi
else
    echo -e "${YELLOW}[4/8] Platform-specific dependencies...${NC}"
    echo -e "${GREEN}[✓] Basic tier - no additional dependencies needed${NC}"
fi
echo

# ============================================================================
# Install Python Dependencies with --break-system-packages
# ============================================================================

echo -e "${YELLOW}[5/8] Installing Python dependencies ($TIER_NAME tier)...${NC}"

# Try installation with --break-system-packages for maximum compatibility
install_python_deps() {
    local deps="$1"
    
    # Try user install first
    if pip3 install $deps --user 2>/dev/null; then
        return 0
    fi
    
    # Try with --break-system-packages (for PEP 668 compliant systems)
    if pip3 install $deps --user --break-system-packages 2>/dev/null; then
        return 0
    fi
    
    # Try system install
    if pip3 install $deps 2>/dev/null; then
        return 0
    fi
    
    # Try system install with --break-system-packages
    if pip3 install $deps --break-system-packages 2>/dev/null; then
        return 0
    fi
    
    # If all else fails, try with sudo
    if sudo pip3 install $deps --break-system-packages 2>/dev/null; then
        return 0
    fi
    
    return 1
}

if install_python_deps "$INSTALL_DEPS"; then
    echo -e "${GREEN}[✓] Dependencies installed successfully${NC}"
else
    echo -e "${RED}[!] Failed to install dependencies${NC}"
    echo -e "${YELLOW}    Please try manual installation:${NC}"
    echo -e "${YELLOW}    pip3 install $INSTALL_DEPS --break-system-packages${NC}"
    exit 1
fi
echo

# ============================================================================
# Verify Installation
# ============================================================================

echo -e "${YELLOW}[6/8] Verifying installation...${NC}"

# Check core dependencies
if python3 -c "import cmd2, rich" 2>/dev/null; then
    echo -e "${GREEN}[✓] Core dependencies verified${NC}"
else
    echo -e "${RED}[!] Core dependencies failed to verify${NC}"
    exit 1
fi

# Check tier-specific dependencies
if [ $TIER -ge 2 ]; then
    if python3 -c "import scapy.all" 2>/dev/null; then
        echo -e "${GREEN}[✓] Scapy installed and working${NC}"
    else
        echo -e "${YELLOW}[!] Scapy import failed - SYN scanning may not work${NC}"
    fi
    
    if python3 -c "import nmap" 2>/dev/null; then
        echo -e "${GREEN}[✓] python-nmap installed and working${NC}"
    else
        echo -e "${YELLOW}[!] python-nmap import failed${NC}"
    fi
fi

if [ $TIER -ge 3 ]; then
    if python3 -c "import requests, bs4, dns" 2>/dev/null; then
        echo -e "${GREEN}[✓] Full tier dependencies verified${NC}"
    else
        echo -e "${YELLOW}[!] Some full tier dependencies may be missing${NC}"
    fi
fi
echo

# ============================================================================
# Make SecV Executable
# ============================================================================

echo -e "${YELLOW}[7/8] Setting executable permissions...${NC}"
chmod +x "$SECV_BIN"

if [ -x "$SECV_BIN" ]; then
    echo -e "${GREEN}[✓] SecV is now executable${NC}\n"
else
    echo -e "${RED}[!] Failed to make SecV executable${NC}"
    exit 1
fi

# ============================================================================
# Create Directory Structure
# ============================================================================

if [ ! -d "$SCRIPT_DIR/tools" ]; then
    echo -e "${YELLOW}Creating tools directory...${NC}"
    mkdir -p "$SCRIPT_DIR/tools"
    echo -e "${GREEN}[✓] Tools directory created${NC}"
fi

if [ ! -d "$SCRIPT_DIR/.cache" ]; then
    mkdir -p "$SCRIPT_DIR/.cache"
fi

# ============================================================================
# System-Wide Installation
# ============================================================================

echo -e "${YELLOW}[8/8] System-wide installation...${NC}\n"

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                   ║${NC}"
echo -e "${CYAN}║   System-Wide Installation (Optional)                             ║${NC}"
echo -e "${CYAN}║                                                                   ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Would you like to install SecV system-wide?${NC}"
echo -e "${BLUE}This will allow you to run 'secV' from anywhere on your system.${NC}"
echo -e "${BLUE}Installation location: /usr/local/bin/secV${NC}\n"

read -p "Install system-wide? [y/N]: " -n 1 -r
echo

INSTALLED_GLOBALLY=false
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}Installing system-wide (requires sudo)...${NC}"
    
    INSTALL_PATH="/usr/local/bin/secV"
    
    # Remove existing installation if present
    if [ -L "$INSTALL_PATH" ] || [ -f "$INSTALL_PATH" ]; then
        echo -e "${YELLOW}Removing existing installation...${NC}"
        sudo rm -f "$INSTALL_PATH"
    fi
    
    # Create symlink
    sudo ln -s "$SECV_BIN" "$INSTALL_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] SecV installed to $INSTALL_PATH${NC}"
        echo -e "${GREEN}[✓] You can now run 'secV' from anywhere!${NC}\n"
        INSTALLED_GLOBALLY=true
    else
        echo -e "${RED}[!] Failed to install system-wide${NC}"
        echo -e "${YELLOW}    You can still run SecV with: ./secV${NC}"
    fi
else
    echo -e "\n${BLUE}[i] Local installation complete.${NC}"
    echo -e "${BLUE}    Run SecV with: ./secV${NC}"
fi

# ============================================================================
# Installation Summary
# ============================================================================

echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                   ║${NC}"
echo -e "${CYAN}║   Installation Complete!                                          ║${NC}"
echo -e "${CYAN}║                                                                   ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}✓ SecV v2.2 is ready to use!${NC}\n"

echo -e "${BLUE}Installation Summary:${NC}"
echo -e "  Tier: ${GREEN}$TIER_NAME${NC}"
echo -e "  Python: ${GREEN}$PYTHON_VERSION${NC}"
echo -e "  Distribution: ${GREEN}$DISTRO${NC}"
echo -e "  Location: ${GREEN}$SCRIPT_DIR${NC}"

if [ "$INSTALLED_GLOBALLY" = true ]; then
    echo -e "  Global: ${GREEN}Yes${NC} (/usr/local/bin/secV)\n"
else
    echo -e "  Global: ${YELLOW}No${NC} (local only)\n"
fi

echo -e "${BLUE}Quick Start:${NC}"
if [ "$INSTALLED_GLOBALLY" = true ]; then
    echo -e "  ${YELLOW}secV${NC}                    # Start SecV shell"
else
    echo -e "  ${YELLOW}./secV${NC}                  # Start SecV shell"
fi
echo -e "  ${YELLOW}help${NC}                    # Show all commands"
echo -e "  ${YELLOW}show modules${NC}            # List available modules\n"

echo -e "${GREEN}Happy Hacking! 🔒${NC}\n"
