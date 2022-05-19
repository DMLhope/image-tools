#!/bin/bash
echo "=========================in_chroot==================================="
DEVICE="$1"
conf_path="/installer/installer_settings.json"

bash /installer/install_package.sh

bash /installer/setup_bootloader.sh "$DEVICE" 

bash /installer/setup_user.sh $conf_path
bash /installer/setup_locale.sh $conf_path
bash /installer/setup_timezone.sh $conf_path
bash /installer/setup_keyboard.sh $conf_path
bash /installer/setup_lightdm.sh