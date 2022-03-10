#!/usr/bin/env bash

set -xe

codename=""
chroot_path="/tmp/build_chroot"
repo_url=""

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
        cp -rv ./hooks-data "$chroot_path" 
    else
        echo "nothing copy to chroot"
    fi
    if [ -f ./hooks/hooks.sh ];then
        echo "start do in chroot"
        chroot "$chroot_path" ./hooks.sh 
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
    chroot_build
    mount_dir
    do_inchroot
    umount_dir
    mk_squashfs
}

main "$@"


