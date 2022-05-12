#!/bin/bash
echo "=========================in_chroot==================================="
DEVICE="$1"
bash /installer/setup_bootloader.sh "$DEVICE" |tee -a /var/log/installer.log