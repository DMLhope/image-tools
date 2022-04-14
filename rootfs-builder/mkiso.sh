#!/bin/bash
sqfs_path="./filesystem.squashfs"
rootfs_path=""

user_check(){  
    if [ "$USER" != "root" ];then
        echo "please use root user or sudo !"
        exit 1
    fi
}

opts_check(){
    if [[ $# != 1 ]];then
        echo "Options miss checkout option need at least one opts !"
        exit 2
    fi
}
un_squashfs(){
    if [ -f $sqfs_path ];then
        unsquashfs $sqfs_path
    else
        echo "can not find $sqfs_path"
        exit 1
    fi
}
copy_rootfs(){
    if [ -d ./squashfs-root ]; then
        cp --sparse=always "$rootfs_path" ./squashfs-root/rootfs.img
        sync
    fi
}

copy_install_scipts(){
    if [ -d ./squashfs-root ] && [ -f ./serialport_installer.sh ]; then
        cp -v ./serialport_installer.sh ./squashfs-root/usr/bin/
        chmod a+x ./squashfs-root/usr/bin/serialport_installer.sh
    fi
}

mk_binary(){
    mkdir  -p ./binary
    if [ -d ./include.binary ];then
        rsync -avPh ./include.binary/ ./binary/
        mkdir -p ./binary/live
        cp -v ./squashfs-root/boot/initrd* ./binary/boot/initrd.img
        cp -v ./squashfs-root/boot/vmlinu* ./binary/boot/vmlinuz
        mksquashfs ./squashfs-root ./binary/live/filesystem.squashfs
        sync
    fi 
}

enable_autologin(){
    chroot_path="./squashfs-root"
   	sed -i "s|ExecStart=-/sbin/agetty|ExecStart=-/sbin/agetty --autologin root |g" "$chroot_path"/lib/systemd/system/serial-getty@.service
    sed -i "/ExecStart/i\ExecStartPre=-/bin/stty -F /dev/%I speed 115200 -opost" "$chroot_path"/lib/systemd/system/serial-getty@.service
    for i in {0..7}
    do
        ln -s /lib/systemd/system/serial-getty@.service "$chroot_path"/etc/systemd/system/getty.target.wants/serial-getty@ttyS"${i}".service
    done
}

mk_iso(){
    xorriso -as mkisofs -V UnionTechOS -R -r -J -joliet-long -l -cache-inodes -quiet \
        -o ./new.iso ./binary
}

main(){
    user_check
    opts_check "$@"
    rootfs_path=$(realpath "$1")
    un_squashfs
    copy_rootfs
    copy_install_scipts
    enable_autologin
    mk_binary
    mk_iso

}

main "$@"
