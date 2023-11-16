#!/usr/bin/env bash
set -xe

codename=""
chroot_path="/tmp/build_chroot"
repo_url=""
img_size="2048"
time_flag=$(date +%Y%m%d%H%M%S)
rootfs_name="root-""$time_flag"".img"


creat_dir(){
    mkdir -p "$chroot_path"
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
    debootstrap --no-check-gpg "$codename" "$chroot_path" "$repo_url"
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
    cp -v /etc/resolv.conf "$chroot_path"/etc/resolv.conf
    if [ -d ./hooks/package.list ];then
        echo "start copy package.list to chroot"
        cp -rv ./hooks/package.list "$chroot_path" 
    else
        echo "no package.list copy to chroot"
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

    echo "" > "$chroot_path"/etc/resolv.conf
    rm -rf "$chroot_path"/hooks.sh
    rm -rf "$chroot_path"/package.list
}

umount_dir(){
    umount "$chroot_path"/dev
    umount "$chroot_path"/sys
    umount "$chroot_path"/proc
}

mk_rootfs_img(){
    dd if=/dev/zero of="$rootfs_name" bs=1M count="$img_size"
    mkfs.ext4 -F "$rootfs_name"
    rootfs_mnt="$rootfs_name"-mnt
    mkdir -p $rootfs_mnt
    mount "$rootfs_name" "$rootfs_mnt"
    rsync -av "$chroot_path"/* "$rootfs_mnt"
    umount "$rootfs_mnt"
    e2fsck -f "$rootfs_name"
    resize2fs "$rootfs_name"
}


main(){
    user_check
    opts_check "$@"
    codename="$1"
    repo_url="$2"
    echo "codename:" "$codename", "repo_url: " "$repo_url"
    creat_dir
    chroot_build
    mount_dir
    do_inchroot
    umount_dir
    mk_rootfs_img
}

main "$@"


