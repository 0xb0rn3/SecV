# SecV Installation Guide

## Quick Install

```bash
git clone https://github.com/secvulnhub/secV && cd secV && bash install.sh
```

The installer detects your distro (Arch, Debian, Fedora, Alpine) and handles everything:
compiles the Go binary, installs system tools (`adb`, `apktool`, `nmap`, etc.),
installs Python module dependencies, and optionally installs system-wide:

| Path | Contents |
|------|----------|
| `/usr/local/bin/secV` | the binary |
| `/var/lib/secv/tools/` | all module scripts |
| `/var/lib/secv/update.py` | updater |
| `~/.secv/cache/` | per-user history (auto-created) |

```bash
./secV                          # from repo directory (dev)
secV                            # after system install
SECV_HOME=/custom/path secV    # explicit path override
```

---

## What the Installer Does

1. Detects distro and package manager (`pacman`, `apt`, `dnf`, `apk`)
2. Checks Python 3.8+ and installs if missing
3. Installs system tools from `rqm.md` (`nmap`, `adb`, `apktool`, etc.)
4. Downloads `bore` for WAN tunneling
5. Checks Go 1.21+ and installs if missing
6. Compiles the Go binary: `go build -ldflags="-s -w" -o secV .`
7. Installs Python packages from `rqm.md` via pip
8. **Optional system install** (prompted):
   - `sudo install -m755 secV /usr/local/bin/secV`
   - `sudo cp -r tools/ /var/lib/secv/tools/`
   - `sudo install -m755 update.py /var/lib/secv/update.py`

---

## Requirements

| Requirement | Version | Purpose |
|-------------|---------|---------|
| Go | 1.21+ | Compile the secV binary |
| Python | 3.8+ | Module execution |
| pip | any | Python dependency installation |
| git | any | Cloning and updates |

**OS:** Linux (Arch, Debian/Ubuntu, Fedora, Alpine) or macOS

---

## Manual Installation

If you prefer to install step by step:

```bash
# 1. Compile the binary
go build -o secV .

# 2. Install Python dependencies
pip3 install -r requirements.txt --break-system-packages

# 3. Make executable and run
chmod +x secV
./secV
```

---

## Installation Options

### Local (no sudo required)
```bash
./install.sh
# Answer N when asked about system-wide install
./secV           # run from repo directory
```

### System-Wide (recommended)
```bash
./install.sh
# Answer Y when asked about system-wide install
secV             # available from any directory
```

### Manual system-wide install
```bash
sudo install -m755 secV /usr/local/bin/secV
sudo mkdir -p /var/lib/secv
sudo cp -r tools/ /var/lib/secv/
sudo install -m755 update.py /var/lib/secv/update.py
```

### Custom path override
Use `SECV_HOME` to point the binary at any tools directory — useful for multiple installs or CI:
```bash
SECV_HOME=/opt/secv-dev secV
```

The loader searches in this order:
1. `$SECV_HOME` env var
2. Directory of the real binary (follows symlinks), if `tools/` exists there
3. `/var/lib/secv/` (standard system install location)
4. Current working directory (fallback for portable/ad-hoc use)

---

## Verification

```bash
./secV
secV ❯ show modules    # lists: netrecon, mac_spoof, wifi_monitor, adsec, winadsec, android_pentest, ios_pentest, websec, ctfpwn
secV ❯ show categories
secV ❯ help
secV ❯ exit
```

---

## Directory Structure

**Repository (dev / local install):**

```
secV/
├── secV                          # Compiled Go binary
├── main.go                       # Shell source
├── install.sh                    # Installer
├── uninstall.sh                  # Uninstaller
├── update.py                     # Updater
├── gen_module.py                 # Module JSON generator
├── rqm.md                        # Global requirements manifest — all modules, all distros
├── requirements.txt              # pip-only convenience (mirrors rqm.md #python section)
├── go.mod / go.sum               # Go module manifest
└── tools/
    ├── network/
    │   ├── netrecon/             # Multi-engine network recon
    │   ├── mac_spoof/            # Connection-aware MAC rotator
    │   └── wifi_monitor/         # Smart WiFi monitor + threat detector
    ├── AD/
    │   ├── linux/                # adsec — Linux-side AD pentest
    │   └── windows/              # winadsec — Windows AD post-exploitation
    ├── mobile/
    │   ├── android/              # Android pentesting suite
    │   └── ios/                  # iOS pentesting suite
    ├── web/
    │   └── websec/               # Full-stack web attack surface tool
    └── ctf/                      # ctfpwn — CTF autopwn
```

**After system-wide install (`install.sh` → Y):**

```
/usr/local/bin/
└── secV                          # binary

/var/lib/secv/
├── update.py                     # updater (secV update command targets this)
└── tools/                        # full copy of tools/ from repo
    ├── network/  ...
    ├── AD/       ...
    ├── mobile/   ...
    ├── web/      ...
    └── ctf/      ...

~/.secv/
└── cache/                        # history file, per-user (auto-created)
```

---

## Module Dependencies

All dependencies are declared in `rqm.md`. Run `install.sh` to install everything. For pip-only environments: `pip3 install -r requirements.txt --break-system-packages`

`install.sh` also installs system tools (`adb`, `apktool`, `jadx`, `nmap`, `masscan`, `arp-scan`) and [bore](https://github.com/ekzhang/bore) for WAN tunneling.

For raw socket operations (SYN scanning, masscan) run with `sudo`:
```bash
sudo secV
# or
sudo ./secV
```

---

## Updating

```bash
secV ❯ update                 # interactive update (inside shell)

python3 update.py             # apply updates
python3 update.py --status    # check component status
python3 update.py --verify    # integrity check
python3 update.py --rollback  # restore last backup
```

**After `git pull` on a system install**, refresh `/var/lib/secv/` manually:

```bash
cd /path/to/secv-repo
git pull
go build -ldflags="-s -w" -o secV .
sudo install -m755 secV /usr/local/bin/secV
sudo cp -r tools/ /var/lib/secv/
sudo install -m755 update.py /var/lib/secv/update.py
```

---

## Uninstalling

```bash
chmod +x uninstall.sh && ./uninstall.sh    # removes /usr/local/bin/secV

# Remove system data directory
sudo rm -rf /var/lib/secv/

# Remove per-user cache
rm -rf ~/.secv/

# Full removal of repo
cd .. && rm -rf secV/
```

---

## Troubleshooting

**Modules not found after system install**
```bash
# The binary can't find tools/ — re-copy them
sudo mkdir -p /var/lib/secv
sudo cp -r tools/ /var/lib/secv/
sudo install -m755 update.py /var/lib/secv/update.py

# Or point the binary at the repo directly
SECV_HOME=/path/to/secv-repo secV
```

**Go binary won't compile**
```bash
sudo pacman -S go          # Arch
sudo apt install golang    # Debian/Ubuntu
brew install go            # macOS

go mod tidy
go build -o secV .
```

**Module not found after adding**
```bash
secV ❯ reload
```

**Permission denied**
```bash
chmod +x secV install.sh
```

**Missing adb / apktool**
```bash
./install.sh               # re-run installer — it skips already-installed components
```

**Python dependency missing**
```bash
pip3 install -r requirements.txt --break-system-packages
```

---

## Support

- Issues: https://github.com/secvulnhub/secV/issues
- Docs: [README.md](README.md), [MODULES.md](MODULES.md), [CONTRIBUTING.md](CONTRIBUTING.md)
