#!/bin/bash
set -xe

rootfs_path=""

opts_check(){
    if [[ $# != 1 ]];then
        echo "请接上rootfs的路径作为参数"
        exit 2
    fi
}
user_check(){  
    if [ "$USER" != "root" ];then
        echo "please use root user or sudo !"
        exit 1
    fi
}
mount_rootfs(){
    losetup -fP "$rootfs_path"
    devicepart_path=$(losetup -l |grep "$rootfs_path"|awk '{print $1}')p1
    mount_path="$rootfs_path"_mountdir
    mkdir -p "$mount_path"
    mount "$devicepart_path" "$mount_path"
    mount -t sysfs sysfs   "$mount_path"/sys/
    mount -t proc proc     "$mount_path"/proc/
    mount -t devtmpfs udev "$mount_path"/dev
    mount -t devpts devpts "$mount_path"/dev/pts/
}

main(){
    opts_check "$@"
    user_check
    rootfs_path=$(realpath "$1")
    mount_rootfs
}

main "$@"