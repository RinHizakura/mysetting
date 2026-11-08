#!/usr/bin/env bash
#
# setup-pi.sh — one-shot setup for a Raspberry Pi 4 (Ubuntu) used as a kernel bench/debug box.
# Run ON THE PI:   sudo ./setup-pi.sh            (idempotent; re-run any time)
#
# Env knobs:  PI_USER=<account for console auto-login and ~/.bashrc>   (default: the sudo user)
#             TS_AUTHKEY=tskey-auth-...  TS_HOSTNAME=<name>  TS_SSH=0   (Tailscale; see step 4)
#
# 1. GPIO UART console: enable_uart=1 + dtoverlay=disable-bt (PL011 on GPIO 14/15),
#    console=serial0,115200. Wiring from a 3.3 V USB-serial adapter: GND-pin6, RX-pin8 (TXD),
#    TX-pin10 (RXD), no VCC. Host side: screen /dev/ttyUSB0 115200.
# 2. Console auto-login for PI_USER on ttyAMA0 and ttyS1.
# 3. systemd OSC 3008 escapes garble the prompt over serial: stub its bash hooks in ~/.bashrc.
# 4. Tailscale: install, enable, IP forwarding, `tailscale up --ssh`; without TS_AUTHKEY a login
#    URL is printed to authorize in a browser. Last, because it may wait for you.
#

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo: sudo $0" >&2; exit 1; }
PI_USER="${PI_USER:-${SUDO_USER:-$(ls /home | head -n1)}}"
id "$PI_USER" &>/dev/null || { echo "no such user: $PI_USER" >&2; exit 1; }
info() { echo "==> $*"; }

# ensure_line FILE LINE REGEX: append LINE unless REGEX already matches
ensure_line() { grep -qE "$3" "$1" || printf '%s\n' "$2" >> "$1"; }

# ---- 1. UART console ----------------------------------------------------------
info "GPIO UART console"
CONFIG=/boot/firmware/config.txt CMDLINE=/boot/firmware/cmdline.txt
cp -n "$CONFIG" "$CONFIG.bak"; cp -n "$CMDLINE" "$CMDLINE.bak"   # once, before the first edit
ensure_line "$CONFIG" "enable_uart=1"        '^[[:space:]]*enable_uart=1'
ensure_line "$CONFIG" "dtoverlay=disable-bt" '^[[:space:]]*dtoverlay=disable-bt'
grep -q 'console=serial0,115200' "$CMDLINE" || sed -i '1 s|^|console=serial0,115200 |' "$CMDLINE"  # stays one line

# ---- 2. console auto-login ----------------------------------------------------
info "auto-login $PI_USER on ttyAMA0 ttyS1"
for tty in ttyAMA0 ttyS1; do
  d=/etc/systemd/system/serial-getty@$tty.service.d; mkdir -p "$d"
  printf '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin %s --noclear %%I $TERM\n' "$PI_USER" > "$d/override.conf"
  systemctl enable "serial-getty@$tty.service" >/dev/null 2>&1 || true
done
systemctl daemon-reload

# ---- 3. bash prompt over serial ---------------------------------------------------
info "stub systemd OSC 3008 hooks in ~$PI_USER/.bashrc"
BASHRC=$(eval echo "~$PI_USER")/.bashrc; MARKER="# disable systemd OSC 3008 context"
[[ -f "$BASHRC" ]] && sed -i "/^$MARKER\$/,+2d" "$BASHRC"
printf '%s\n__systemd_osc_context_precmdline() { :; }\n__systemd_osc_context_ps0() { :; }\n' "$MARKER" >> "$BASHRC"
chown "$PI_USER:" "$BASHRC"

# ---- 4. Tailscale -----------------------------------------------------------------
info "Tailscale"
command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled
printf 'net.ipv4.ip_forward=1\nnet.ipv6.conf.all.forwarding=1\n' > /etc/sysctl.d/99-tailscale.conf
sysctl -q -p /etc/sysctl.d/99-tailscale.conf
if tailscale status >/dev/null 2>&1; then
  info "tailscale already up: $(tailscale ip -4 | head -n1)"
else
  up=( "--hostname=${TS_HOSTNAME:-$(hostname)}" ); [[ "${TS_SSH:-1}" == 1 ]] && up+=( --ssh ); [[ -n "${TS_AUTHKEY:-}" ]] && up+=( "--authkey=$TS_AUTHKEY" )
  [[ -n "${TS_AUTHKEY:-}" ]] || info "open the login URL below in a browser to authorize this node"
  tailscale up "${up[@]}"
fi

info "done — reboot to apply the console changes"
