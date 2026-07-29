#!/usr/bin/env bash
#
# disable-osc-context.sh — Stop systemd OSC 3008 escape sequences from
# garbling the prompt, by overriding its hooks in ~/.bashrc.

set -euo pipefail

BASHRC="${HOME}/.bashrc"
MARKER="# disable systemd OSC 3008 context"

# Replace any block from a previous run (marker + 2 lines)
[[ -f "$BASHRC" ]] && sed -i "/^${MARKER}\$/,+2d" "$BASHRC"

cat >> "$BASHRC" <<EOF
$MARKER
__systemd_osc_context_precmdline() { :; }
__systemd_osc_context_ps0() { :; }
EOF

echo "Applied to $BASHRC ✓  Open a new shell (or 'source ~/.bashrc') to take effect."
echo "Revert: delete the 3 lines starting at the marker in $BASHRC"
