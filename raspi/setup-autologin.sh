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

# ---- 2. Target consoles (PL011 UART ttyAMA0 + ttyS1) ----
TTYS=(ttyAMA0 ttyS1)
GETTY="/sbin/agetty"
info "Target services: ${TTYS[*]/#/serial-getty@}"
echo

# ---- 3. Configure each console ----
for tty in "${TTYS[@]}"; do
  SERVICE="serial-getty@${tty}.service"
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

  # Back up existing override
  if [[ -f "$OVERRIDE_FILE" ]]; then
    backup="${OVERRIDE_FILE}.bak.$(date +%s)"
    cp -a "$OVERRIDE_FILE" "$backup"
    warn "Backed up existing file to $backup"
  fi

  # Write override
  mkdir -p "$OVERRIDE_DIR"
  cat > "$OVERRIDE_FILE" <<EOF
[Service]
ExecStart=
ExecStart=-${GETTY} --autologin ${USERNAME} --noclear %I \$TERM
EOF
  info "Override file written for $tty"

  # Enable so it starts on next boot even if no override existed before
  systemctl enable "$SERVICE" >/dev/null 2>&1 || true
  echo
done

# ---- 4. Apply ----
systemctl daemon-reload
for tty in "${TTYS[@]}"; do
  SERVICE="serial-getty@${tty}.service"
  systemctl restart "$SERVICE" || warn "restart of $SERVICE failed (normal if it is the tty you are currently using; takes effect after reboot)"
done
info "Setup complete ✓"
echo
echo "Verify:  systemctl cat serial-getty@ttyAMA0.service serial-getty@ttyS1.service"
echo "Revert:  sudo rm /etc/systemd/system/serial-getty@{ttyAMA0,ttyS1}.service.d/override.conf && sudo systemctl daemon-reload"
echo
echo "Run ${BOLD}sudo reboot${RESET} to test."
