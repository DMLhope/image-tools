#!/usr/bin/env bash

set -xe

codename=""
chroot_path="/tmp/build_chroot"
repo_url=""
img_size="4096"
time_flag=$(date +%Y%m%d%H%M%S)
rootfs_name="root-""$time_flag"".img"

mkrootfs_img(){
    dd if=/dev/zero of=./"$rootfs_name" bs=1M count=0 seek="$img_size"
    parted -s ./"$rootfs_name" mklabel msdos mkpart primary ext3 0% 100%
}

mount_rootfs(){
    losetup -fP ./"$rootfs_name"
    devicepart_path=$(losetup -l |grep "$rootfs_name"|awk '{print $1}')p1
    mkfs.ext3 "$devicepart_path"
    if [ -b "$devicepart_path" ];then
        [ ! -d $chroot_path ] && mkdir $chroot_path
        mount "$devicepart_path" $chroot_path
    else
        echo "device load path Error,Please check use : losetup -l "
        exit 1
    fi
}

umount_rootfs(){
    umount $chroot_path
    device_path=$(losetup -l |grep "$rootfs_name"|awk '{print $1}')
    losetup -d "$device_path"
}

user_check(){  
    if [ "$USER" != "root" ];then
        echo "please use root user or sudo !"
        exit 1
    fi
}

opts_check(){
    if [[ $# != 2 ]];then
        echo "Options miss checkout option need at least two opts !"
        exit 2
    fi
}

deps_check(){
    apt update
    apt install debootstrap squashfs-tools
}

chroot_build(){
    debootstrap "$codename" "$chroot_path" "$repo_url"
}

mount_dir(){
    mount --bind /dev "$chroot_path"/dev
    mount -t sysfs sys "$chroot_path"/sys
    mount -t proc proc "$chroot_path"/proc
}

do_inchroot(){
    if [ ! -d ./hooks ];then
        echo "nothing to do in chroot"
        return 0
    fi

    if [ -d ./hooks/hooks-data ];then
        echo "start copy data to chroot"
        cp -rv ./hooks/hooks-data "$chroot_path" 
    else
        echo "nothing copy to chroot"
    fi
    if [ -f ./hooks/hooks.sh ];then
        echo "start do in chroot"
        cp -v ./hooks/hooks.sh "$chroot_path"/
        chmod a+x "$chroot_path"/hooks.sh
        chroot "$chroot_path" /hooks.sh 
    else
        echo "do nothing in chroot"
    fi
}

umount_dir(){
    umount "$chroot_path"/dev
    umount "$chroot_path"/sys
    umount "$chroot_path"/proc
}

mk_squashfs(){
    mksquashfs "$chroot_path" ./filesystem.squashfs
}
main(){
    user_check
    opts_check "$@"
    codename="$1"
    repo_url="$2"
    echo "codename:" "$codename", "repo_url: " "$repo_url"
    mkrootfs_img
    mount_rootfs
    chroot_build
    mount_dir
    do_inchroot
    umount_dir
    mk_squashfs
    umount_rootfs
}

main "$@"


