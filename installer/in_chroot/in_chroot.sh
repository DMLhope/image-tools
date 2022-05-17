#!/bin/bash
echo "=========================in_chroot==================================="
DEVICE="$1"
conf_path="/"
bash /installer/setup_bootloader.sh "$DEVICE" |tee -a /var/log/installer.log
# 
bash /installer/set_user.sh
bash /installer/set_timezone.sh