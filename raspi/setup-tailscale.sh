#!/usr/bin/env bash
#
# setup-tailscale.sh
# Install and configure Tailscale on a Raspberry Pi 4 running Ubuntu.
# Purpose: reach the Pi (ping / SSH) from an external PC on a different
# network, even though the Pi only has a private 192.168.x.x address
# behind NAT.
#
# Run this ON THE PI (not on the x86 host):
#   sudo ./setup-tailscale.sh
#
# Unattended (pre-generate a key at
# https://login.tailscale.com/admin/settings/keys):
#   sudo TS_AUTHKEY=tskey-auth-xxxx ./setup-tailscale.sh
#
# What it does:
#   1. Install Tailscale via the official script (skip if already present)
#   2. Enable and start the tailscaled service
#   3. Enable IP forwarding (for optional subnet routing later)
#   4. Bring the node up with --ssh and a stable hostname
# Idempotent — re-running will not duplicate anything.

set -euo pipefail

# ---- Tunables --------------------------------------------------------------
HOSTNAME_TS="${TS_HOSTNAME:-$(hostname)}"   # Name shown in the Tailscale admin
ENABLE_SSH="${TS_SSH:-1}"                    # 1 = enable Tailscale SSH
TS_AUTHKEY="${TS_AUTHKEY:-}"                 # Set => non-interactive login
SYSCTL_FILE="/etc/sysctl.d/99-tailscale.conf"

# ---- Colors ----------------------------------------------------------------
if [[ -t 1 ]]; then
  RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
else
  RED=''; GREEN=''; YELLOW=''; BOLD=''; RESET=''
fi
info()  { echo "${GREEN}==>${RESET} $*"; }
warn()  { echo "${YELLOW}!! ${RESET} $*"; }
err()   { echo "${RED}xx ${RESET} $*" >&2; }

# ---- Preflight checks ------------------------------------------------------
if [[ ${EUID} -ne 0 ]]; then
  err "Please run with sudo:  sudo $0"
  exit 1
fi

echo "${BOLD}Raspberry Pi Tailscale setup${RESET}"
echo

# ---- 1. Install Tailscale --------------------------------------------------
if command -v tailscale >/dev/null 2>&1; then
  info "Tailscale already installed: $(tailscale version | head -n1)"
else
  info "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
  info "Installed"
fi

# ---- 2. Enable the daemon --------------------------------------------------
info "Enabling tailscaled service"
systemctl enable --now tailscaled
info "tailscaled is running"

# ---- 3. Enable IP forwarding (harmless; needed for subnet routing later) ---
if grep -qE '^net.ipv4.ip_forward=1' "$SYSCTL_FILE" 2>/dev/null; then
  info "IP forwarding already configured, skipping"
else
  printf 'net.ipv4.ip_forward=1\nnet.ipv6.conf.all.forwarding=1\n' > "$SYSCTL_FILE"
  sysctl -p "$SYSCTL_FILE" >/dev/null
  info "IP forwarding enabled (${SYSCTL_FILE})"
fi

# ---- 4. Bring the node up --------------------------------------------------
UP_ARGS=( "--hostname=${HOSTNAME_TS}" )
[[ "$ENABLE_SSH" == "1" ]] && UP_ARGS+=( "--ssh" )
[[ -n "$TS_AUTHKEY" ]]     && UP_ARGS+=( "--authkey=${TS_AUTHKEY}" )

info "Connecting to Tailscale"
if [[ -z "$TS_AUTHKEY" ]]; then
  echo
  warn "A login URL will appear below — open it in a browser and authorize this machine."
  echo
fi
tailscale up "${UP_ARGS[@]}"

# ---- Done ------------------------------------------------------------------
TS_IP="$(tailscale ip -4 2>/dev/null | head -n1 || true)"
LOGIN_USER="${SUDO_USER:-$(ls /home 2>/dev/null | head -n1)}"

cat <<EOF

${BOLD}DONE.${RESET} Summary:
   - Hostname     : ${HOSTNAME_TS}
   - Tailscale IP : ${TS_IP:-(not assigned yet — confirm you authorized the node above)}
   - Tailscale SSH: $([[ "$ENABLE_SSH" == "1" ]] && echo enabled || echo disabled)

From another device signed in to the SAME Tailscale account:
   ping ${TS_IP:-100.x.y.z}
   ssh ${LOGIN_USER:-ubuntu}@${TS_IP:-100.x.y.z}
$([[ "$ENABLE_SSH" == "1" ]] && echo "   tailscale ssh ${LOGIN_USER:-ubuntu}@${HOSTNAME_TS}")

Verify:  tailscale status
Revert:  sudo tailscale down        (go offline)
         sudo tailscale logout      (unlink this node)
EOF
