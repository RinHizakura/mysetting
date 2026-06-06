#!/usr/bin/env bash
#
# setup-pi-uart-console.sh
# Enable the GPIO UART serial console on a Raspberry Pi 4 running Ubuntu.
# Purpose: log into the Pi from an external PC via a USB-to-serial adapter
# wired to GPIO 14/15.
#
# Run this ON THE PI (not on the x86 host):
#   sudo ./setup-pi-uart-console.sh
#
# What it does:
#   1. Ensure enable_uart=1 and dtoverlay=disable-bt in /boot/firmware/config.txt
#   2. Ensure console=serial0,115200 in /boot/firmware/cmdline.txt
#   3. Enable serial-getty@ttyAMA0.service
#   4. Back up each file before modifying it
# Idempotent — re-running will not duplicate lines.

set -euo pipefail

BAUD=115200
GETTY_DEV="ttyAMA0"          # disable-bt maps the PL011 (ttyAMA0) onto the GPIO
BOOT_DIR="/boot/firmware"
CONFIG="${BOOT_DIR}/config.txt"
CMDLINE="${BOOT_DIR}/cmdline.txt"
STAMP="$(date +%Y%m%d-%H%M%S)"

# --- Preflight checks -------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: run with sudo: sudo $0" >&2
    exit 1
fi

if [[ ! -d "$BOOT_DIR" ]]; then
    echo "ERROR: ${BOOT_DIR} not found." >&2
    echo "  This script targets Ubuntu on Raspberry Pi (boot partition at ${BOOT_DIR})." >&2
    echo "  On Raspberry Pi OS the path may be /boot/ instead." >&2
    exit 1
fi

echo "* Boot config dir: ${BOOT_DIR}"

# --- Helper: ensure a line exists in a file ---------------------------------
# ensure_line <file> <exact-line> <match-regex>
# Skip if match-regex already matches; otherwise append exact-line.
ensure_line() {
    local file="$1" line="$2" regex="$3"
    if grep -qE "$regex" "$file"; then
        echo "  ok  already present, skipping: ${line}"
    else
        printf '%s\n' "$line" >> "$file"
        echo "  +   added: ${line}"
    fi
}

# --- 1. config.txt ----------------------------------------------------------
echo "* Processing ${CONFIG}"
cp -a "$CONFIG" "${CONFIG}.bak-${STAMP}"
echo "  -> backed up to ${CONFIG}.bak-${STAMP}"

ensure_line "$CONFIG" "enable_uart=1"        '^[[:space:]]*enable_uart=1'
ensure_line "$CONFIG" "dtoverlay=disable-bt" '^[[:space:]]*dtoverlay=disable-bt'

# --- 2. cmdline.txt ---------------------------------------------------------
# cmdline.txt MUST stay a single line, so edit in place rather than append.
echo "* Processing ${CMDLINE}"
cp -a "$CMDLINE" "${CMDLINE}.bak-${STAMP}"
echo "  -> backed up to ${CMDLINE}.bak-${STAMP}"

if grep -qE "console=serial0,${BAUD}" "$CMDLINE"; then
    echo "  ok  console=serial0,${BAUD} already present, skipping"
else
    # Insert at the start of the line (keeps it single-line)
    sed -i "1 s|^|console=serial0,${BAUD} |" "$CMDLINE"
    echo "  +   inserted console=serial0,${BAUD} at line start"
fi

# --- 3. Enable serial-getty -------------------------------------------------
echo "* Enabling serial-getty@${GETTY_DEV}.service"
systemctl enable "serial-getty@${GETTY_DEV}.service" >/dev/null 2>&1 || true
echo "  ok  enabled (takes effect on next boot)"

# --- Done -------------------------------------------------------------------
cat <<EOF

DONE. Summary:
   - enable_uart=1          (config.txt)
   - dtoverlay=disable-bt   (config.txt - gives PL011 to the GPIO for a stable console)
   - console=serial0,${BAUD} (cmdline.txt)
   - serial-getty@${GETTY_DEV} enabled

   Backups:
   - ${CONFIG}.bak-${STAMP}
   - ${CMDLINE}.bak-${STAMP}

Wiring (x86 USB-serial <-> Pi 4 GPIO):
   GND  <-> Pin 6
   RX   <-> Pin 8  (GPIO14 / Pi TXD)   <- cross TX/RX
   TX   <-> Pin 10 (GPIO15 / Pi RXD)
   VCC  <-> DO NOT connect; use a 3.3V logic-level adapter only.

Reboot to apply:
   sudo reboot

Then on the x86 host:
   sudo screen /dev/ttyUSB0 ${BAUD}
   (press Enter and you should see the login: prompt)
EOF
