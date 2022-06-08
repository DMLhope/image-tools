#!/bin/bash
if [ $# -eq 1 ];then
mount_path=$(realpath $1)
umount -l "$mount_path"/dev/pts/
umount -l "$mount_path"/dev
umount -l "$mount_path"/proc/
umount -l "$mount_path"/sys/
fi