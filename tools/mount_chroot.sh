#!/bin/bash
if [ $# -eq 1 ];then
mount_path=$(realpath $1)
mount -t sysfs sysfs   "$mount_path"/sys/
mount -t proc proc     "$mount_path"/proc/
mount -t devtmpfs udev "$mount_path"/dev
mount -t devpts devpts "$mount_path"/dev/pts/
fi