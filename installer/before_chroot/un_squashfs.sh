#!/bin/bash

squashfs_path=$1

thread=1

if [ $(cat /proc/cpuinfo |grep "processor" | wc -l) -gt 1 ];then
    thread=$(cat /proc/cpuinfo |grep "processor" | wc -l)
fi
unsquashfs -d /target -f -p "$thread" \
  "${squashfs_path}" > /dev/shm/unsquashfs_progress || \
  echo "unsquashfs failed, ${squashfs_path}"
sync 
echo 3 > /proc/sys/vm/drop_caches