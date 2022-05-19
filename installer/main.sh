#!/bin/bash

chroot_path="/target"
work_path="/installer"
settings_path="$work_path/installer_settings.json"

user_check(){  
    if [ "$USER" != "root" ];then
        echo "please use root user or sudo !"
        exit 3
    fi
}



main(){
    
    squashfs_path=$(realpath "$1") 
    if [ ! -f "$squashfs_path" ];then
        echo "squashfs path error, please check"
        exit 1
    fi
    DEVICE="$2"
    if [ ! -b "$DEVICE" ];then
        echo "device path error, please check"
        exit 2
    fi

    user_check

    cd  $work_path || exit
    cd ./auto-part/ || exit
    bash ./auto_part.sh "$DEVICE"
    bash ./mount_target.sh "$DEVICE"
    unsquashfs -d $chroot_path -f "$squashfs_path" 
    bash ./create_fstab.sh
    cd ..
    bash ./tools/mount_chroot.sh "$chroot_path"
    cp -rv ./in_chroot "$chroot_path"/installer
    cp -v $settings_path "$chroot_path"/$settings_path
    chmod a+x "$chroot_path"/installer/*.sh
    chroot "$chroot_path" /installer/in_chroot.sh "$DEVICE"

    bash ./tools/umount_chroot.sh "$chroot_path"
    bash ./auto-part/umount_target.sh
    
}

main "$@"