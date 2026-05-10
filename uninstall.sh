#!/usr/bin/env bash
# secV uninstaller — removes system-wide install paths set by install.sh

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
DIM='\033[2m'
RST='\033[0m'

ok()   { echo -e "${GRN}[+]${RST} $*"; }
warn() { echo -e "${YLW}[!]${RST} $*"; }
info() { echo -e "${CYN}[*]${RST} $*"; }

BIN_PATH="/usr/local/bin/secV"
DATA_DIR="/var/lib/secv"
CACHE_DIR="$HOME/.secv"

echo -e "${CYN}secV uninstall${RST}\n"

found_any=false

# ── Binary ────────────────────────────────────────────────────────────────────
if [ -f "$BIN_PATH" ] || [ -L "$BIN_PATH" ]; then
    found_any=true
    warn "binary   $BIN_PATH"
fi

# ── Data directory ────────────────────────────────────────────────────────────
if [ -d "$DATA_DIR" ]; then
    found_any=true
    du_out=$(du -sh "$DATA_DIR" 2>/dev/null | cut -f1)
    warn "data     $DATA_DIR  (${du_out:-?})"
fi

# ── User cache ────────────────────────────────────────────────────────────────
if [ -d "$CACHE_DIR" ]; then
    found_any=true
    du_out=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
    warn "cache    $CACHE_DIR  (${du_out:-?})"
fi

if [ "$found_any" = false ]; then
    echo -e "${DIM}nothing to remove — no system install found${RST}"
    echo -e "${DIM}repo files in $(pwd) are unchanged${RST}"
    exit 0
fi

echo ""
read -r -p "Remove the above? [y/N] " _ans
if [[ ! "$_ans" =~ ^[Yy]$ ]]; then
    echo -e "${DIM}cancelled${RST}"
    exit 0
fi

echo ""

# Remove binary
if [ -f "$BIN_PATH" ] || [ -L "$BIN_PATH" ]; then
    sudo rm -f "$BIN_PATH" && ok "removed  $BIN_PATH"
fi

# Remove data directory
if [ -d "$DATA_DIR" ]; then
    sudo rm -rf "$DATA_DIR" && ok "removed  $DATA_DIR"
fi

# Remove user cache (no sudo — it's in $HOME)
if [ -d "$CACHE_DIR" ]; then
    read -r -p "Also remove ~/.secv/ (shell history, cache)? [y/N] " _cache_ans
    if [[ "$_cache_ans" =~ ^[Yy]$ ]]; then
        rm -rf "$CACHE_DIR" && ok "removed  $CACHE_DIR"
    else
        echo -e "${DIM}kept     $CACHE_DIR${RST}"
    fi
fi

echo ""
ok "System install removed"
echo -e "${DIM}Repo files in $(pwd) are unchanged.${RST}"
echo -e "${DIM}To fully remove: cd .. && rm -rf $(basename "$(pwd)")${RST}"
