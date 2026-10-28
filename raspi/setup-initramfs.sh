#!/usr/bin/env bash
#
# setup-initramfs.sh — Configure initramfs-tools to use dep instead of most for MODULES.

set -euo pipefail
sudo sed -i 's/^MODULES=most/MODULES=dep/' /etc/initramfs-tools/initramfs.conf
grep -E '^MODULES=' /etc/initramfs-tools/initramfs.conf
