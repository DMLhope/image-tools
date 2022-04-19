#!/bin/bash
#代码参考deepin-installer auto_path.sh

declare DEVICE EFI=false

# Check boot mode is UEFI or not.
check_efi_mode(){
  [ "$(uname -m)" == "sw_64" ] && declare -g EFI=true
  [ -d "/sys/firmware/efi" ] && declare -g EFI=true
  # 允许接收一个参数来强制指定使用efi
  [ x"$1" = "xtrue" ] && declare -g EFI=true
}

#卸载设备
# 可以接收一个参数类似/dev/sda
umount_devices(){
  # Umount device
  if [ $# == 1 ];then
    umount -lf "$1"* &>/dev/null
  fi

  # Umount all swap partitions.
  swapoff -a

  # Umount /target
  [ -d /target ] && umount -R /target
}

# 监视udev事件队列，并且在所有事件全部处理完成之后退出。
# Flush kernel message.
flush_message(){
  udevadm settle --timeout=5
}

# Format partition at $1 with filesystem $2 with label $3.
format_part(){
  local part_path="$1" part_fs="$2" part_label="$3"
  local part_fs_="$part_fs"
  if [ "$part_fs_" = "recovery" ]; then
     part_fs_=ext4
  fi

  yes |\
  case "$part_fs_" in
    vfat)
      mkfs.vfat -F32 -n "$part_label" "$part_path";;
    fat32)
      mkfs.vfat -F32 -n "$part_label" "$part_path";;
    efi)
      mkfs.vfat -F32 -n "$part_label" "$part_path";;
    fat16)
      mkfs.vfat -F16 -n "$part_label" "$part_path";;
    ntfs)
      mkfs.ntfs --fast -L "$part_label" "$part_path";;
    linux-swap)
      mkswap "$part_path";;
    swap)
      mkswap "$part_path";;
    ext4)
      if is_loongson || is_sw; then
        mkfs.ext4 -O ^64bit -F -L "$part_label" "$part_path"
      else
        mkfs.ext4 -L "$part_label" "$part_path"
      fi
    ;;
    xfs)
      mkfs.xfs -f -L "$part_label" "$part_path"
    ;;
    *)
      mkfs -t "$part_fs" -L "$part_label" "$part_path";;
  esac || error "Failed to create $part_fs filesystem on $part_path!"
}

# 查找容量最大的设备
# get_max_capacity_device(){
#   local name size max_device max_size=0
#   while read name size; do
#     if ((size >= max_size)); then
#       max_size="$size"
#       max_device="/dev/$name"
#     fi
#   done < <(lsblk -ndb -o NAME,SIZE)
#   DEVICE="$max_device"
# }

main(){
    卸载设备
    启动模式检查
    设置分区表
    创建分区

}

