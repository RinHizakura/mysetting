#!/usr/bin/env bash
#
# setup-autologin.sh — Interactive console auto-login setup for RPi4 Ubuntu Server
#
# Usage (run on the RPi4):
#   chmod +x setup-autologin.sh
#   sudo ./setup-autologin.sh
#
set -euo pipefail

# ---- Colors ----
if [[ -t 1 ]]; then
  RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
else
  RED=''; GREEN=''; YELLOW=''; BOLD=''; RESET=''
fi
info()  { echo "${GREEN}==>${RESET} $*"; }
warn()  { echo "${YELLOW}!! ${RESET} $*"; }
err()   { echo "${RED}xx ${RESET} $*" >&2; }
ask()   { local p="$1" d="${2:-}" a; read -r -p "${BOLD}${p}${RESET}${d:+ [$d]}: " a; echo "${a:-$d}"; }

# ---- Require root ----
if [[ ${EUID} -ne 0 ]]; then
  err "Please run with sudo:  sudo $0"
  exit 1
fi

echo "${BOLD}RPi4 Ubuntu console auto-login setup${RESET}"
echo

# ---- 1. Select user account ----
default_user="${SUDO_USER:-}"
[[ -z "$default_user" ]] && default_user="$(ls /home 2>/dev/null | head -n1)"
USERNAME="$(ask 'Account to auto-login' "$default_user")"

if ! id "$USERNAME" &>/dev/null; then
  err "Account '$USERNAME' does not exist. Please check and re-run."
  exit 1
fi
info "Selected account: $USERNAME"
echo

# ---- 2. Target console (fixed: PL011 UART serial console ttyAMA0) ----
SERVICE="serial-getty@ttyAMA0.service"
GETTY="/sbin/agetty"
info "Target service: $SERVICE"
echo

# ---- 3. Confirm ----
OVERRIDE_DIR="/etc/systemd/system/${SERVICE}.d"
OVERRIDE_FILE="${OVERRIDE_DIR}/override.conf"

echo "About to write: ${BOLD}${OVERRIDE_FILE}${RESET}"
echo "----------------------------------------"
cat <<EOF
[Service]
ExecStart=
ExecStart=-${GETTY} --autologin ${USERNAME} --noclear %I \$TERM
EOF
echo "----------------------------------------"

# ---- 4. Back up existing override ----
if [[ -f "$OVERRIDE_FILE" ]]; then
  backup="${OVERRIDE_FILE}.bak.$(date +%s)"
  cp -a "$OVERRIDE_FILE" "$backup"
  warn "Backed up existing file to $backup"
fi

# ---- 5. Write override ----
mkdir -p "$OVERRIDE_DIR"
cat > "$OVERRIDE_FILE" <<EOF
[Service]
ExecStart=
ExecStart=-${GETTY} --autologin ${USERNAME} --noclear %I \$TERM
EOF
info "Override file written"

# ---- 6. Apply ----
systemctl daemon-reload
systemctl restart "$SERVICE" || warn "restart failed (normal if it is the tty you are currently using; takes effect after reboot)"
info "Setup complete ✓"
echo
echo "Verify:  systemctl cat $SERVICE"
echo "Revert:  sudo rm $OVERRIDE_FILE && sudo systemctl daemon-reload"
echo
echo "Run ${BOLD}sudo reboot${RESET} to test."
