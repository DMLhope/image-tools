#!/bin/bash
#代码参考deepin-installer auto_path.sh
export LANG=C LC_ALL=C

declare DEVICE EFI=false JSON_PATH="./full_disk_policy.json"
declare SWAP_SIZE="2048"

#检查参数
check_opts(){
  if [ $# -ge 1 ];then
    echo $@
  else
    echo "need options!!!"
    exit 1
  fi
}

# Check whether current platform is loongson or not.
is_loongson() {
  case $(uname -m) in
    loongson | mips* | loongarch64)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Check whether current platform is sw or not.
is_sw() {
  case $(uname -m) in
    sw*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# shell json
shell_json(){
  json_path=$JSON_PATH
  for ((i=0;i<10;i++))
  do
    local device=$DEVICE
    local part_num=$i
    local filesystem=$(jq -r ".["$i"].filesystem" "$json_path")
    local mountPoint=$(jq -r ".["$i"].mountPoint" "$json_path")
    local label=$(jq -r ".["$i"].label" "$json_path")
    local usage=$(jq -r ".["$i"].usage" "$json_path")
    local alignStart=$(jq -r ".["$i"].alignStart" "$json_path")
    if [ "$filesystem" = "null" ];then
      echo "=============== Json End ================"
      break
    fi

    creat_part $device $part_num $filesystem $label $usage
    
  done
}

# Check boot mode is UEFI or not.
check_efi_mode(){
  is_sw && declare -g EFI=true
  [ -d "/sys/firmware/efi" ] && declare -g EFI=true
  # 允许接收一个参数来强制指定使用efi
  [ x"$1" = "xtrue" ] && declare -g EFI=true
}

#卸载设备
# 可以接收一个参数类似/dev/sda
umount_devices(){
  # Umount device
  if [ $# = 1 ];then
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


# Create new partition table.
new_part_table(){
  if [ "x$EFI" = "xtrue" ] || is_sw ; then
    local part_table="gpt"
  else
    local part_table="msdos"
  fi

  echo "part_table=${part_table}"
  parted -s "$DEVICE" mktable "$part_table" ||\
    error "Failed to create $part_table partition on $DEVICE!"

  echo "new part table: $DEVICE = $part_table"
}

# 获取下一个分区的开头
get_next_part_start_pos() {
    local dev_info=$1
    # 计算分区信息
    local offset=$(fdisk -l $dev_info | grep  "^$dev_info" | wc -l)
        PART_NUM=$offset
    if [ $offset = '0' ]; then
        offset=2048
    else
        local end=$(expr $(fdisk -l $dev_info -o END | sed -n '$p') + 1)
        offset=$end
    fi

    echo $offset
}

get_part_mountpoint() {
    local LABEL=$1
    if [ "x$LABEL" = "xEFI" ]; then
        echo "/boot/efi"
    elif [ "x$LABEL" = "xBoot" ]; then
        echo "/boot"
    elif [ "x$LABEL" = "xBackup" ];then
        echo "/recovery"
    elif [ "x$LABEL" = "xSWAP" ];then
	      echo "swap"
    elif [ "x$LABEL" = "xRoota" ];then
        echo "/"
    elif [ "x$LABEL" = "x_dde_data" ];then
        echo "$(installer_get DI_DATA_MOUNT_POINT)"
    else
        echo ""
    fi
}

get_part_number() {
    local PART_PATH=$1
    echo "${PART_PATH##*[a-zA-Z]}"
}

creat_part(){
  local device=$1
  local part_num=$2
  local filesystem=$3
  local label=$4
  local usage=$5
  
  if [ $part_num -eq 0 ];then
    part_num=""
    device_part=${device}${part_num}
  else
    device_part=${device}${part_num}
  fi
  part_start=$(get_next_part_start_pos $dev)

  if [ x"$EFI" = "xfalse" ];then
    echo "Create extended partition..."
    part_end=$((part_start + $(get_system_disk_extend_size)))
    parted -s "$DEVICE" mkpart extended "${part_start}s" "${part_end}s" ||\
      error "Failed to create extended partition on $DEVICE!"
  fi

}

main(){
  # 检查参数
  # 卸载设备
  # 启动模式检查
  # 设置分区表
  # 创建分区
  DEVICE=$1
  umount_devices "$DEVICE"
  check_efi_mode
  new_part_table "$DEVICE"
  shell_json

}
