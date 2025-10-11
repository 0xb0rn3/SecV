#!/usr/bin/env bash
#
# SecV Installation Script v2.4 - Go Loader Edition
# Enhanced with Go compilation and automatic update checking
#
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SECV_BIN="$SCRIPT_DIR/secV"
MAIN_GO="$SCRIPT_DIR/main.go"
REQUIREMENTS_FILE="$SCRIPT_DIR/requirements.txt"
VERSION="2.4.0"

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
â•"â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
â•'                                                                   â•'
â•'   â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•—   â–ˆâ–ˆâ•—                             â•'
â•'   â–ˆâ–ˆâ•"â•â•â•â•â•â–ˆâ–ˆâ•"â•â•â•â•â•â–ˆâ–ˆâ•"â•â•â•â•â•â–ˆâ–ˆâ•'   â–ˆâ–ˆâ•'                             â•'
â•'   â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ•'     â–ˆâ–ˆâ•'   â–ˆâ–ˆâ•'                             â•'
â•'   â•šâ•â•â•â•â–ˆâ–ˆâ•'â–ˆâ–ˆâ•"â•â•â•  â–ˆâ–ˆâ•'     â•šâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•"â•                             â•'
â•'   â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•'â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â•šâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â•šâ–ˆâ–ˆâ–ˆâ–ˆâ•"â•                              â•'
â•'   â•šâ•â•â•â•â•â•â•â•šâ•â•â•â•â•â•â• â•šâ•â•â•â•â•â•  â•šâ•â•â•â•                               â•'
â•'                                                                   â•'
â•'   SecV Installer v2.4 - Go Loader Edition                        â•'
â•'   High-Performance Compiled Loader                               â•'
â•'                                                                   â•'
â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
EOF
echo -e "${NC}"

echo -e "${BLUE}[*] Starting SecV installation...${NC}\n"

# ============================================================================
# Detect System Information
# ============================================================================

echo -e "${YELLOW}[1/11] Detecting system information...${NC}"
DISTRO=$(detect_distro)
echo -e "${GREEN}[âœ"] Detected distribution: ${DISTRO}${NC}"

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
    echo -e "${GREEN}[âœ"] Operating system: macOS${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
    echo -e "${GREEN}[âœ"] Operating system: Linux${NC}"
else
    OS_TYPE="unknown"
    echo -e "${YELLOW}[!] Unknown operating system: $OSTYPE${NC}"
fi
echo

# ============================================================================
# Check Prerequisites
# ============================================================================

echo -e "${YELLOW}[2/11] Checking Python installation...${NC}"
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
        arch|manjaro|endeavouros|archcraft)
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

echo -e "${GREEN}[âœ"] Python $PYTHON_VERSION found${NC}\n"

# ============================================================================
# Check pip
# ============================================================================

echo -e "${YELLOW}[3/11] Checking pip installation...${NC}"
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
        arch|manjaro|endeavouros|archcraft)
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
echo -e "${GREEN}[âœ"] pip3 found${NC}\n"

# ============================================================================
# Check Go Installation
# ============================================================================

echo -e "${YELLOW}[4/11] Checking Go installation...${NC}"
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}[!] Go is not installed!${NC}"
    echo -e "${YELLOW}    Installing Go...${NC}"
    
    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop|kali)
            sudo apt-get update && sudo apt-get install -y golang-go
            ;;
        fedora|rhel|centos|rocky|almalinux)
            sudo dnf install -y golang || sudo yum install -y golang
            ;;
        arch|manjaro|endeavouros|archcraft)
            sudo pacman -S --noconfirm go
            ;;
        opensuse*|suse)
            sudo zypper install -y go
            ;;
        alpine)
            sudo apk add go
            ;;
        void)
            sudo xbps-install -Sy go
            ;;
        *)
            echo -e "${RED}[!] Unable to install Go automatically.${NC}"
            echo -e "${YELLOW}    Please install Go 1.18+ from https://golang.org/dl/${NC}"
            exit 1
            ;;
    esac
    
    # Verify installation
    if ! command -v go &> /dev/null; then
        echo -e "${RED}[!] Go installation failed${NC}"
        exit 1
    fi
fi

GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
echo -e "${GREEN}[âœ"] Go $GO_VERSION found${NC}\n"

# ============================================================================
# Installation Tier Selection
# ============================================================================

echo -e "${CYAN}â•"â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${CYAN}â•'                                                                   â•'${NC}"
echo -e "${CYAN}â•'   Installation Tier Selection                                     â•'${NC}"
echo -e "${CYAN}â•'                                                                   â•'${NC}"
echo -e "${CYAN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}\n"

echo -e "${YELLOW}Choose your installation tier:${NC}\n"

echo -e "${GREEN}1) Basic${NC} - Core functionality only (~5MB)"
echo -e "   â€¢ cmd2, rich, argcomplete (required)"
echo -e "   â€¢ TCP connect scanning"
echo -e "   â€¢ All modules work with reduced features"
echo -e "   ${BLUE}Best for: Minimal footprint, testing${NC}\n"

echo -e "${GREEN}2) Standard${NC} - Core + scanning tools (~50MB) ${MAGENTA}â­ Recommended${NC}"
echo -e "   â€¢ Basic + scapy, python-nmap"
echo -e "   â€¢ SYN stealth scanning (requires root)"
echo -e "   â€¢ Nmap integration"
echo -e "   â€¢ MAC vendor lookup & device recognition"
echo -e "   â€¢ Full port scanner features"
echo -e "   ${BLUE}Best for: Most users, penetration testing${NC}\n"

echo -e "${GREEN}3) Full${NC} - All features (~100MB)"
echo -e "   â€¢ All dependencies from requirements.txt"
echo -e "   â€¢ HTTP technology detection (30+ technologies)"
echo -e "   â€¢ Web scraping capabilities"
echo -e "   â€¢ DNS operations & enumeration"
echo -e "   â€¢ SSH, crypto operations"
echo -e "   â€¢ Complete module support"
echo -e "   ${BLUE}Best for: Advanced users, all features${NC}\n"

echo -e "${GREEN}4) Elite${NC} - Full + ultra-fast scanning"
echo -e "   â€¢ Everything in Full tier"
echo -e "   â€¢ Masscan binary for 10k+ ports/sec scanning"
echo -e "   â€¢ Internet-scale port scanning"
echo -e "   â€¢ Requires root for masscan"
echo -e "   ${BLUE}Best for: Large-scale reconnaissance${NC}\n"

read -p "Select tier [1-4] (default: 2): " TIER
TIER=${TIER:-2}

case $TIER in
    1)
        TIER_NAME="Basic"
        INSTALL_DEPS="cmd2>=2.4.3 rich>=13.0.0 argcomplete>=3.0.0"
        INSTALL_MASSCAN=false
        ;;
    2)
        TIER_NAME="Standard"
        INSTALL_DEPS="cmd2>=2.4.3 rich>=13.0.0 argcomplete>=3.0.0 scapy>=2.5.0 python-nmap>=0.7.1"
        INSTALL_MASSCAN=false
        ;;
    3)
        TIER_NAME="Full"
        if [ -f "$REQUIREMENTS_FILE" ]; then
            INSTALL_DEPS=$(grep -v '^#' "$REQUIREMENTS_FILE" | grep -v '^$' | sed 's/#.*//' | tr '\n' ' ' | xargs)
        else
            echo -e "${RED}[!] requirements.txt not found!${NC}"
            exit 1
        fi
        INSTALL_MASSCAN=false
        ;;
    4)
        TIER_NAME="Elite"
        if [ -f "$REQUIREMENTS_FILE" ]; then
            INSTALL_DEPS=$(grep -v '^#' "$REQUIREMENTS_FILE" | grep -v '^$' | sed 's/#.*//' | tr '\n' ' ' | xargs)
        else
            echo -e "${RED}[!] requirements.txt not found!${NC}"
            exit 1
        fi
        INSTALL_MASSCAN=true
        ;;
    *)
        echo -e "${RED}[!] Invalid selection. Using Standard tier.${NC}"
        TIER=2
        TIER_NAME="Standard"
        INSTALL_DEPS="cmd2>=2.4.3 rich>=13.0.0 argcomplete>=3.0.0 scapy>=2.5.0 python-nmap>=0.7.1"
        INSTALL_MASSCAN=false
        ;;
esac

echo -e "\n${GREEN}[âœ"] Selected: $TIER_NAME tier${NC}\n"

# ============================================================================
# Platform-Specific Dependencies
# ============================================================================

if [ $TIER -ge 2 ]; then
    echo -e "${YELLOW}[5/11] Checking platform-specific dependencies...${NC}"
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        case "$DISTRO" in
            ubuntu|debian|linuxmint|pop|kali)
                if ! dpkg -l | grep -q libpcap-dev; then
                    echo -e "${YELLOW}[i] Scapy requires libpcap-dev on Debian/Ubuntu${NC}"
                    read -p "Install libpcap-dev? (recommended) [Y/n]: " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                        sudo apt-get update && sudo apt-get install -y libpcap-dev
                        echo -e "${GREEN}[âœ"] libpcap-dev installed${NC}"
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
                        echo -e "${GREEN}[âœ"] libpcap-devel installed${NC}"
                    fi
                fi
                ;;
            arch|manjaro|endeavouros|archcraft)
                if ! pacman -Qi libpcap &>/dev/null; then
                    echo -e "${YELLOW}[i] Scapy requires libpcap on Arch${NC}"
                    read -p "Install libpcap? (recommended) [Y/n]: " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                        sudo pacman -S --noconfirm libpcap
                        echo -e "${GREEN}[âœ"] libpcap installed${NC}"
                    fi
                fi
                ;;
        esac
    elif [[ "$OS_TYPE" == "macos" ]]; then
        echo -e "${GREEN}[âœ"] macOS - no additional dependencies needed${NC}"
    fi
else
    echo -e "${YELLOW}[5/11] Platform-specific dependencies...${NC}"
    echo -e "${GREEN}[âœ"] Basic tier - no additional dependencies needed${NC}"
fi
echo

# ============================================================================
# Install Python Dependencies
# ============================================================================

echo -e "${YELLOW}[6/11] Installing Python dependencies ($TIER_NAME tier)...${NC}"

install_python_deps() {
    local deps="$1"
    
    echo -e "${CYAN}Attempting installation with multiple strategies...${NC}"
    
    echo -e "${DIM}[1/5] Trying: pip3 install --user${NC}"
    if pip3 install $deps --user 2>/dev/null; then
        echo -e "${GREEN}[âœ"] Success with user install${NC}"
        return 0
    fi
    
    echo -e "${DIM}[2/5] Trying: pip3 install --user --break-system-packages${NC}"
    if pip3 install $deps --user --break-system-packages 2>/dev/null; then
        echo -e "${GREEN}[âœ"] Success with user install + break-system-packages${NC}"
        return 0
    fi
    
    echo -e "${DIM}[3/5] Trying: pip3 install (system)${NC}"
    if pip3 install $deps 2>/dev/null; then
        echo -e "${GREEN}[âœ"] Success with system install${NC}"
        return 0
    fi
    
    echo -e "${DIM}[4/5] Trying: pip3 install --break-system-packages${NC}"
    if pip3 install $deps --break-system-packages 2>/dev/null; then
        echo -e "${GREEN}[âœ"] Success with system install + break-system-packages${NC}"
        return 0
    fi
    
    echo -e "${DIM}[5/5] Trying: sudo pip3 install --break-system-packages${NC}"
    if sudo pip3 install $deps --break-system-packages 2>/dev/null; then
        echo -e "${GREEN}[âœ"] Success with sudo install + break-system-packages${NC}"
        return 0
    fi
    
    return 1
}

if install_python_deps "$INSTALL_DEPS"; then
    echo -e "${GREEN}[âœ"] Dependencies installed successfully${NC}"
else
    echo -e "${RED}[!] Failed to install dependencies${NC}"
    exit 1
fi
echo

# ============================================================================
# Install Masscan (Elite Tier)
# ============================================================================

if [ "$INSTALL_MASSCAN" = true ]; then
    echo -e "${YELLOW}[7/11] Installing masscan (Elite tier)...${NC}"
    
    if command -v masscan &> /dev/null; then
        MASSCAN_VERSION=$(masscan --version 2>&1 | head -n1 | awk '{print $3}')
        echo -e "${GREEN}[âœ"] masscan already installed (version: $MASSCAN_VERSION)${NC}"
    else
        echo -e "${YELLOW}[i] masscan not found. Installing...${NC}"
        
        case "$DISTRO" in
            ubuntu|debian|linuxmint|pop|kali)
                sudo apt-get update && sudo apt-get install -y masscan
                ;;
            fedora|rhel|centos|rocky|almalinux)
                sudo dnf install -y masscan || sudo yum install -y masscan
                ;;
            arch|manjaro|endeavouros|archcraft)
                sudo pacman -S --noconfirm masscan
                ;;
            *)
                echo -e "${YELLOW}[!] Masscan not available in package manager${NC}"
                echo -e "${YELLOW}    Install manually: https://github.com/robertdavidgraham/masscan${NC}"
                ;;
        esac
    fi
else
    echo -e "${YELLOW}[7/11] Masscan installation...${NC}"
    echo -e "${GREEN}[âœ"] Skipped (not selected for $TIER_NAME tier)${NC}"
fi
echo

# ============================================================================
# Compile Go Loader
# ============================================================================

echo -e "${YELLOW}[8/11] Compiling Go loader...${NC}"

if [ ! -f "$MAIN_GO" ]; then
    echo -e "${RED}[!] main.go not found at $MAIN_GO${NC}"
    exit 1
fi

echo -e "${CYAN}Building high-performance compiled loader...${NC}"

# Compile with optimizations
cd "$SCRIPT_DIR"
if go build -ldflags="-s -w" -o secV main.go; then
    echo -e "${GREEN}[âœ"] Go loader compiled successfully${NC}"
    
    # Get binary size
    BINARY_SIZE=$(du -h secV | cut -f1)
    echo -e "${GREEN}[âœ"] Binary size: $BINARY_SIZE${NC}"
else
    echo -e "${RED}[!] Go compilation failed${NC}"
    exit 1
fi
echo

# ============================================================================
# Verify Installation
# ============================================================================

echo -e "${YELLOW}[9/11] Verifying installation...${NC}"

if python3 -c "import cmd2, rich" 2>/dev/null; then
    echo -e "${GREEN}[âœ"] Core dependencies verified${NC}"
else
    echo -e "${RED}[!] Core dependencies failed to verify${NC}"
    exit 1
fi

if [ $TIER -ge 2 ]; then
    if python3 -c "import scapy.all" 2>/dev/null; then
        echo -e "${GREEN}[âœ"] Scapy installed and working${NC}"
    else
        echo -e "${YELLOW}[!] Scapy import failed - SYN scanning may not work${NC}"
    fi
    
    if python3 -c "import nmap" 2>/dev/null; then
        echo -e "${GREEN}[âœ"] python-nmap installed and working${NC}"
    else
        echo -e "${YELLOW}[!] python-nmap import failed${NC}"
    fi
fi

if [ $TIER -ge 3 ]; then
    if python3 -c "import requests, bs4, dns" 2>/dev/null; then
        echo -e "${GREEN}[âœ"] Full tier dependencies verified${NC}"
    else
        echo -e "${YELLOW}[!] Some full tier dependencies may be missing${NC}"
    fi
fi

if [ -x "$SECV_BIN" ]; then
    echo -e "${GREEN}[âœ"] SecV binary is executable${NC}"
else
    echo -e "${YELLOW}[!] Setting executable permissions...${NC}"
    chmod +x "$SECV_BIN"
    echo -e "${GREEN}[âœ"] Permissions set${NC}"
fi
echo

# ============================================================================
# Create Required Directories
# ============================================================================

echo -e "${YELLOW}[10/11] Creating required directories...${NC}"

mkdir -p "$SCRIPT_DIR/tools" "$SCRIPT_DIR/.cache"
echo -e "${GREEN}[âœ"] Directories created${NC}\n"

# ============================================================================
# System-Wide Installation
# ============================================================================

echo -e "${YELLOW}[11/11] System-wide installation...${NC}\n"

echo -e "${CYAN}â•"â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${CYAN}â•'                                                                   â•'${NC}"
echo -e "${CYAN}â•'   System-Wide Installation (Optional)                             â•'${NC}"
echo -e "${CYAN}â•'                                                                   â•'${NC}"
echo -e "${CYAN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}\n"

echo -e "${YELLOW}Would you like to install SecV system-wide?${NC}"
echo -e "${BLUE}This will allow you to run 'secV' from anywhere on your system.${NC}"
echo -e "${BLUE}Installation location: /usr/local/bin/secV${NC}\n"

read -p "Install system-wide? [y/N]: " -n 1 -r
echo

INSTALLED_GLOBALLY=false
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}Installing system-wide (requires sudo)...${NC}"
    
    INSTALL_PATH="/usr/local/bin/secV"
    
    if [ -L "$INSTALL_PATH" ] || [ -f "$INSTALL_PATH" ]; then
        echo -e "${YELLOW}Removing existing installation...${NC}"
        sudo rm -f "$INSTALL_PATH"
    fi
    
    sudo ln -s "$SECV_BIN" "$INSTALL_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[âœ"] SecV installed to $INSTALL_PATH${NC}"
        echo -e "${GREEN}[âœ"] You can now run 'secV' from anywhere!${NC}\n"
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

echo -e "\n${CYAN}â•"â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${CYAN}â•'                                                                   â•'${NC}"
echo -e "${CYAN}â•'   Installation Complete!                                          â•'${NC}"
echo -e "${CYAN}â•'                                                                   â•'${NC}"
echo -e "${CYAN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}\n"

echo -e "${GREEN}âœ" SecV v$VERSION is ready to use!${NC}\n"

echo -e "${BLUE}Installation Summary:${NC}"
echo -e "  Tier: ${GREEN}$TIER_NAME${NC}"
echo -e "  Python: ${GREEN}$PYTHON_VERSION${NC}"
echo -e "  Go: ${GREEN}$GO_VERSION${NC}"
echo -e "  Distribution: ${GREEN}$DISTRO${NC}"
echo -e "  Location: ${GREEN}$SCRIPT_DIR${NC}"
echo -e "  Binary: ${GREEN}Compiled (Go)${NC}"
echo -e "  Size: ${GREEN}$BINARY_SIZE${NC}"

if [ "$INSTALLED_GLOBALLY" = true ]; then
    echo -e "  Global: ${GREEN}Yes${NC} (/usr/local/bin/secV)\n"
else
    echo -e "  Global: ${YELLOW}No${NC} (local only)\n"
fi

# Installed features
echo -e "${BLUE}Installed Features:${NC}"
echo -e "  ${GREEN}âœ"${NC} High-performance compiled loader (Go)"
echo -e "  ${GREEN}âœ"${NC} Automatic update checking on startup"
echo -e "  ${GREEN}âœ"${NC} Enhanced shell with validation & formatting"
echo -e "  ${GREEN}âœ"${NC} Capability detection & dependency warnings"
echo -e "  ${GREEN}âœ"${NC} Parameter validation (type, range, options)"
echo -e "  ${GREEN}âœ"${NC} Rich output formatting for complex data"

if [ $TIER -ge 2 ]; then
    echo -e "  ${GREEN}âœ"${NC} SYN stealth scanning (scapy)"
    echo -e "  ${GREEN}âœ"${NC} Nmap integration"
    echo -e "  ${GREEN}âœ"${NC} MAC vendor lookup & device recognition"
fi

if [ $TIER -ge 3 ]; then
    echo -e "  ${GREEN}âœ"${NC} HTTP technology detection (30+ technologies)"
    echo -e "  ${GREEN}âœ"${NC} Web scraping & HTML parsing"
    echo -e "  ${GREEN}âœ"${NC} DNS enumeration & reverse lookup"
    echo -e "  ${GREEN}âœ"${NC} TLS/SSL certificate analysis"
fi

if [ $TIER -ge 4 ] && command -v masscan &> /dev/null; then
    echo -e "  ${GREEN}âœ"${NC} Masscan ultra-fast scanning (10k+ ports/sec)"
fi

echo

echo -e "${BLUE}Quick Start:${NC}"
if [ "$INSTALLED_GLOBALLY" = true ]; then
    echo -e "  ${YELLOW}secV${NC}                    # Start SecV shell"
else
    echo -e "  ${YELLOW}./secV${NC}                  # Start SecV shell"
fi
echo -e "  ${YELLOW}help${NC}                    # Show all commands"
echo -e "  ${YELLOW}show modules${NC}            # List available modules"
echo -e "  ${YELLOW}use portscan${NC}            # Load Elite Port Scanner v3.0"
echo -e "  ${YELLOW}help module${NC}             # View detailed module help\n"

# Important notes
echo -e "${CYAN}Important Notes:${NC}"
echo -e "  ${BLUE}âš¡${NC}  Compiled loader provides 10-100x faster startup"
echo -e "  ${BLUE}âš¡${NC}  Automatic update check on first run (24h interval)"
if [ $TIER -ge 2 ]; then
    echo -e "  ${YELLOW}âš ${NC}  SYN scanning requires root: ${YELLOW}sudo secV${NC}"
fi
if [ $TIER -ge 4 ]; then
    echo -e "  ${YELLOW}âš ${NC}  Masscan requires root: ${YELLOW}sudo secV${NC}"
fi
echo -e "  ${BLUE}â„¹${NC}  Update anytime with: ${YELLOW}secV > update${NC}"
echo -e "  ${BLUE}â„¹${NC}  Module help shows dependency status"
echo -e "  ${BLUE}â„¹${NC}  Missing dependencies show install commands\n"

echo -e "${GREEN}Happy Hacking! ðŸ"'${NC}\n"
