#!/usr/bin/env python3
"""
mac_spoof.py - SecV module (Python)

Reads JSON context from stdin (SecV passes {"target":"...","params":{...}}).
Supports: start (default), stop, status
Targets: iface (single or csv), all_up (boolean)

Creates one background runner per interface at:
  /tmp/secv_mac_spoof_runner_<iface>.py
Pidfile: /tmp/secv_mac_spoof_<iface>.pid
Log: /tmp/secv_mac_spoof_<iface>.log
Original MAC saved: /tmp/secv_mac_orig_<iface>.orig

Requires 'ip' command (iproute2) and root for changes (unless dry_run).
"""

import os
import sys
import json
import subprocess
import time
import random
import signal
from pathlib import Path
from typing import List

# Configuration
INTERVAL = 0.5  # seconds
PREFIX = "02:00:00"  # locally-administered OUI prefix
TMPDIR = Path("/tmp")
RUNNER_TMPL = TMPDIR / "secv_mac_spoof_runner_{iface}.py"
PIDFILE_TMPL = TMPDIR / "secv_mac_spoof_{iface}.pid"
LOGFILE_TMPL = TMPDIR / "secv_mac_spoof_{iface}.log"
ORIG_TMPL = TMPDIR / "secv_mac_orig_{iface}.orig"

# Runner script (python) template
RUNNER_SCRIPT = r'''#!/usr/bin/env python3
import os, sys, time, random, subprocess, signal
IFACE = "{iface}"
INTERVAL = {interval}
PIDFILE = "{pidfile}"
LOGFILE = "{logfile}"
PREFIX = "{prefix}"

def log(msg):
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    try:
        with open(LOGFILE, "a") as f:
            f.write(f"{ts} {msg}\n")
    except Exception:
        pass

def gen_tail():
    return "{:02x}:{:02x}:{:02x}".format(random.randrange(256), random.randrange(256), random.randrange(256))

def set_mac(mac):
    # bring down, set, bring up
    cmds = [
        f"ip link set dev {IFACE} down",
        f"ip link set dev {IFACE} address {mac}",
        f"ip link set dev {IFACE} up"
    ]
    for c in cmds:
        r = subprocess.run(c, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if r.returncode != 0:
            return False, r.stderr.strip()
    return True, ""

def restore_original():
    orig_file = "{orig_file}"
    if os.path.exists(orig_file):
        try:
            with open(orig_file, "r") as f:
                orig = f.read().strip()
            if orig:
                subprocess.run(f"ip link set dev {IFACE} down", shell=True)
                subprocess.run(f"ip link set dev {IFACE} address {orig}", shell=True)
                subprocess.run(f"ip link set dev {IFACE} up", shell=True)
                log(f"RESTORED {IFACE} -> {orig}")
        except Exception as e:
            log(f"RESTORE_FAILED {e}")

def cleanup(signum=None, frame=None):
    try:
        restore_original()
    except Exception:
        pass
    try:
        if os.path.exists(PIDFILE):
            os.remove(PIDFILE)
    except Exception:
        pass
    sys.exit(0)

signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)

# write pidfile
PIDFILE = PIDFILE
with open(PIDFILE, "w") as f:
    f.write(str(os.getpid()))

# main loop
while True:
    tail = gen_tail()
    mac = PREFIX + ":" + tail
    ok, err = set_mac(mac)
    if ok:
        log(f"SET {IFACE} -> {mac}")
    else:
        log(f"FAILED_SET {IFACE} -> {mac} : {err}")
    time.sleep(INTERVAL)
'''

def run_cmd(cmd: str, capture_output: bool = True, check: bool = False):
    return subprocess.run(cmd, shell=True, stdout=(subprocess.PIPE if capture_output else None),
                          stderr=(subprocess.PIPE if capture_output else None), text=True, check=check)

def require_ip():
    if shutil_which("ip") is None:
        print("[-] 'ip' command not found. Install iproute2.", file=sys.stderr)
        return False
    return True

def shutil_which(cmd):
    from shutil import which
    return which(cmd)

# --- helpers for interface discovery and orig mac save/restore

def get_all_up_ifaces() -> List[str]:
    # parse 'ip -o link show up' output, exclude lo
    try:
        proc = run_cmd("ip -o link show up")
        out = proc.stdout or ""
        lines = out.splitlines()
        ifaces = []
        for L in lines:
            # format: "1: lo: <...>"
            parts = L.split(": ")
            if len(parts) >= 2:
                ifname = parts[1].split()[0]
                if ifname != "lo":
                    ifaces.append(ifname)
        return ifaces
    except Exception:
        return []

def iface_exists(iface: str) -> bool:
    return (Path("/sys/class/net") / iface).exists()

def save_original_mac(iface: str):
    p = ORIG_TMPL.format(iface=iface)
    ppath = Path(p)
    if ppath.exists():
        return
    try:
        cur = (Path("/sys/class/net") / iface / "address").read_text().strip()
        if cur:
            ppath.write_text(cur + "\n")
            try:
                ppath.chmod(0o600)
            except Exception:
                pass
    except Exception:
        pass

def read_saved_original(iface: str) -> str:
    p = ORIG_TMPL.format(iface=iface)
    try:
        return Path(p).read_text().strip()
    except Exception:
        return ""

# runner file helpers

def runner_path(iface: str) -> str:
    return str(RUNNER_TMPL.with_name(RUNNER_TMPL.name.format(iface=iface)).with_suffix("")).replace("{iface}", iface).replace("{interval}", str(INTERVAL))

def pidfile_path(iface: str) -> str:
    return PIDFILE_TMPL.format(iface=iface)

def logfile_path(iface: str) -> str:
    return LOGFILE_TMPL.format(iface=iface)

def orig_path(iface: str) -> str:
    return ORIG_TMPL.format(iface=iface)

def build_and_write_runner(iface: str):
    rp = str(RUNNER_TMPL).format(iface=iface)
    pidfile = pidfile_path(iface)
    logfile = logfile_path(iface)
    origfile = orig_path(iface)
    content = RUNNER_SCRIPT.format(
        iface=iface,
        interval=INTERVAL,
        pidfile=pidfile,
        logfile=logfile,
        prefix=PREFIX,
        orig_file=origfile,
    )
    try:
        Path(rp).write_text(content)
        os.chmod(rp, 0o750)
        return rp
    except Exception as e:
        print(f"[-] Failed to write runner for {iface}: {e}", file=sys.stderr)
        return ""

def start_runner(iface: str, dry_run: bool):
    if not iface_exists(iface):
        print(f"[-] Interface '{iface}' does not exist. Skipping.", file=sys.stderr)
        return 2
    pidf = pidfile_path(iface)
    if Path(pidf).exists():
        try:
            pid = int(Path(pidf).read_text().strip())
            os.kill(pid, 0)
            print(f"[*] Runner already active for {iface} (pid {pid}).")
            return 0
        except Exception:
            # stale or invalid pidfile
            try:
                Path(pidf).unlink()
            except Exception:
                pass
    # save orig mac
    save_original_mac(iface)
    rp = build_and_write_runner(iface)
    if not rp:
        return 4
    if dry_run:
        print(f"[DRY-RUN] Would start runner: python3 {rp} (pidfile {pidf}, log {logfile_path(iface)})")
        return 0
    # start runner with nohup
    try:
        p = subprocess.Popen(f"nohup python3 {rp} >/dev/null 2>&1 & echo $!", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        out, err = p.communicate(timeout=5)
        pid = out.strip().splitlines()[-1] if out else ""
        # if runner writes its own pidfile, prefer that, else write this pid
        time.sleep(0.05)
        if not Path(pidf).exists() and pid:
            try:
                Path(pidf).write_text(pid + "\n")
            except Exception:
                pass
        print(f"[+] Started runner for {iface} (pid {pid if pid else 'unknown'}). pidfile: {pidf} log: {logfile_path(iface)}")
        return 0
    except Exception as e:
        print(f"[-] Failed to start runner for {iface}: {e}", file=sys.stderr)
        return 5

def stop_runner(iface: str):
    pidf = pidfile_path(iface)
    if not Path(pidf).exists():
        print(f"[-] No runner pidfile for {iface}.", file=sys.stderr)
        return 2
    try:
        pid = int(Path(pidf).read_text().strip())
    except Exception:
        pid = None
    if pid:
        try:
            os.kill(pid, signal.SIGTERM)
            time.sleep(0.1)
        except Exception:
            pass
    # runner should clean up pidfile and restore original; ensure both removed/restored
    if Path(pidf).exists():
        try:
            Path(pidf).unlink()
        except Exception:
            pass
    # attempt immediate restore if original exists
    orig = read_saved_original(iface)
    if orig:
        try:
            run_cmd(f"ip link set dev {iface} down")
            run_cmd(f"ip link set dev {iface} address {orig}")
            run_cmd(f"ip link set dev {iface} up")
            try:
                Path(orig_path(iface)).unlink()
            except Exception:
                pass
            print(f"[+] Restored {iface} -> {orig}")
        except Exception:
            print(f"[-] Failed to restore {iface} -> {orig}", file=sys.stderr)
    else:
        print(f"[+] Stop requested for {iface}. (No saved original to restore)")

    return 0

def status_runner(iface: str):
    pidf = pidfile_path(iface)
    if not Path(pidf).exists():
        print(f"[-] No runner for {iface}.")
        return 2
    try:
        pid = int(Path(pidf).read_text().strip())
    except Exception:
        pid = None
    if pid:
        try:
            os.kill(pid, 0)
            print(f"[+] Runner active for {iface} (pid {pid}). pidfile: {pidf} log: {logfile_path(iface)}")
            return 0
        except OSError:
            print(f"[-] Stale pidfile for {iface}. Removing.")
            try:
                Path(pidf).unlink()
            except Exception:
                pass
            return 3
    else:
        print(f"[-] Invalid pidfile for {iface}.")
        return 4

# --- main execution: parse JSON from stdin (SecV loader)
def parse_input():
    try:
        raw = sys.stdin.read()
        if not raw:
            return {}
        data = json.loads(raw)
        params = data.get("params", {}) if isinstance(data, dict) else {}
        return params
    except Exception:
        return {}

def prompt_for_iface() -> str:
    try:
        return input("Interface to spoof (single, csv list, or type 'all_up'): ").strip()
    except Exception:
        return ""

def main():
    params = parse_input()
    iface_param = params.get("iface", "") or ""
    all_up_param = params.get("all_up", False)
    action = params.get("action", "start") or "start"
    dry_run = params.get("dry_run", False)

    # normalize booleans/strings
    if isinstance(all_up_param, str):
        all_up_param = all_up_param.lower() in ("1", "true", "yes", "y")
    if isinstance(dry_run, str):
        dry_run = dry_run.lower() in ("1", "true", "yes", "y")

    # interactive prompt if nothing provided
    if not iface_param and not all_up_param:
        ui = prompt_for_iface()
        if ui and ui.lower() == "all_up":
            all_up_param = True
        elif ui:
            iface_param = ui

    # compute target interfaces
    targets: List[str] = []
    if all_up_param:
        targets = get_all_up_ifaces()
    else:
        if iface_param:
            # split csv
            for p in str(iface_param).split(","):
                p2 = p.strip()
                if p2:
                    targets.append(p2)

    if not targets:
        print("[-] No target interfaces found. Provide iface or set all_up true.", file=sys.stderr)
        sys.exit(1)

    # ensure 'ip' present
    if shutil_which("ip") is None:
        print("[-] 'ip' command not found. Install iproute2.", file=sys.stderr)
        sys.exit(2)

    if action == "start":
        if not dry_run and os.geteuid() != 0:
            print("[-] Root required to change MACs. Run with sudo.", file=sys.stderr)
            sys.exit(3)
        for iface in targets:
            start_runner(iface, dry_run)
    elif action == "stop":
        for iface in targets:
            stop_runner(iface)
    elif action == "status":
        for iface in targets:
            status_runner(iface)
    else:
        print(f"[-] Unknown action: {action}", file=sys.stderr)
        sys.exit(4)

if __name__ == "__main__":
    main()
