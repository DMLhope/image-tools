#!/bin/bash
echo "=========================in_chroot==================================="
DEVICE="$1"
work_path="/uos-installer"
conf_path="$work_path/installer_settings.json"

bash $work_path/install_package.sh

bash $work_path/setup_bootloader.sh "$DEVICE" 

bash $work_path/setup_user.sh $conf_path
bash $work_path/setup_locale.sh $conf_path
bash $work_path/setup_timezone.sh $conf_path
bash $work_path/setup_keyboard.sh $conf_path
bash $work_path/setup_lightdm.sh