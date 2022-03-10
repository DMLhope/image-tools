#!/usr/bin/env bash

set -xe
# 确认环境

# 基于debootstrap拉取文件系统

# 挂载必要目录

# 安装需要软件并进行其他操作(hooks)

# 卸载对应目录

# 打包squashfs

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
    if [ -f ./hooks.sh ];then
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


