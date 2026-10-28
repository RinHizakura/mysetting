#!/usr/bin/env bash
#
# setup-debug-timeouts.sh — Increase systemd device and service timeouts for debug kernels
#
# A --debug kernel (KASAN + LOCKDEP) makes udev coldplug take ~80s on a Pi 4,
# which blows systemd's 90s device timeout. Raise the default timeouts and make
# the boot partition mount non-fatal.
#

set -euo pipefail
sudo sed -i -E 's#^(LABEL=system-boot\s+/boot/firmware\s+vfat\s+)defaults(\s)#\1defaults,nofail,x-systemd.device-timeout=300\2#' /etc/fstab
sudo sed -i -E 's/^#?DefaultDeviceTimeoutSec=.*/DefaultDeviceTimeoutSec=300s/; s/^#?DefaultTimeoutStartSec=.*/DefaultTimeoutStartSec=300s/' /etc/systemd/system.conf
grep firmware /etc/fstab
grep -E '^Default(Device)?TimeoutS' /etc/systemd/system.conf
sudo systemctl daemon-reload
