#!/usr/bin/env bash
#
# setup-debug-timeouts.sh — Keep /boot/firmware and slow boots from failing systemd
#
# A --debug kernel (KASAN + LOCKDEP) makes udev coldplug take ~80s on a Pi 4,
# which blows systemd's 90s device timeout. Raise the default timeouts and make
# the boot partition mount non-fatal.
#
# cloud-init-local also mounts /dev/mmcblk0p1 read-only for ~200 ms at boot to read
# its NoCloud seed; when systemd's rw mount of /boot/firmware lands in that window the
# kernel keeps the shared superblock read-only and kernel deploys (tryboot/promote)
# fail with "Read-only file system". Nothing on a bench Pi needs cloud-init, so disable it.
#

set -euo pipefail
sudo sed -i -E 's#^(LABEL=system-boot\s+/boot/firmware\s+vfat\s+)defaults(\s)#\1defaults,nofail,x-systemd.device-timeout=300\2#' /etc/fstab
sudo sed -i -E 's/^#?DefaultDeviceTimeoutSec=.*/DefaultDeviceTimeoutSec=300s/; s/^#?DefaultTimeoutStartSec=.*/DefaultTimeoutStartSec=300s/' /etc/systemd/system.conf
grep firmware /etc/fstab
grep -E '^Default(Device)?TimeoutS' /etc/systemd/system.conf
sudo systemctl daemon-reload
sudo touch /etc/cloud/cloud-init.disabled

# Background jobs that wake CPUs mid-benchmark: unattended-upgrades, apt, fwupd, man-db,
# sysstat every 10 min, and the persistent timers that all fire together right after boot.
sudo systemctl mask --now apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service \
  fwupd-refresh.timer fwupd.service man-db.timer update-notifier-download.timer motd-news.timer \
  sysstat-collect.timer sysstat-summary.timer sysstat-rotate.timer logrotate.timer dpkg-db-backup.timer \
  e2scrub_all.timer xfs_scrub_all.timer fstrim.timer update-notifier-motd.timer snapd.socket snapd.service
