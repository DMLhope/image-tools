#!/bin/bash
# Mount root partition to /target.

# set -x
export LANG=C LC_ALL=C
declare JSON_PATH="/uos-installer/parted.json"
declare DEVICE EFI=false
declare target="/target"
declare fstab_data_flag=false
mkdir -pv ${target}
chown -v root:root ${target}
chmod -v 0755 ${target}

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

# Check boot mode is UEFI or not.
check_efi_mode(){
  is_sw && declare -g EFI=true
  [ -d "/sys/firmware/efi" ] && declare -g EFI=true
  # 允许接收一个参数来强制指定使用efi
  [ ! -z "$1" ] && declare -g EFI=$1
}

find_extended(){
  if [ $(parted -s "$DEVICE" print |grep "msdos"|wc -l) -eq 1 ];then
    if [ $(parted -s "$DEVICE" print |grep extended|wc -l) -eq 1 ];then
      extended_partnum=$(parted -s "$DEVICE" print |grep extended |awk '{print $1}')
      echo "$extended_partnum"
    else
      echo "extended part error!!!"
      exit 3
    fi
  else
    echo 0
  fi
}


get_device_part(){
  device=$1
  part_num=$2
  extended_partnum=$(find_extended)
  if [ $part_num -ge $extended_partnum ] && [ "$extended_partnum" != "0" ];then
    part_num=$((part_num + 1))
  fi
  if [[ "$device" =~ "nvme" ]];then
      device_part=${device}p${part_num}
      echo "$device_part"
  else
      device_part=${device}${part_num}
      echo "$device_part"
  fi
}

find_root(){
  json_path=$JSON_PATH
  device=$DEVICE
  for ((i=0;i<11;i++))
  do
    part_num=$(( i + 1 ))
    mountPoint=$(jq -r ".[""$i""].mountPoint" "$json_path")
    device_part=$(get_device_part "$device" "$part_num")
    if [ "$mountPoint" == "/" ];then
      mount "$device_part" $target
      creat_fstab "$device_part" "$mountPoint"
    fi
  done
}

find_boot(){
  json_path=$JSON_PATH
  device=$DEVICE
  
  for ((i=0;i<11;i++))
  do
    part_num=$(( i + 1 ))
    mountPoint=$(jq -r ".[""$i""].mountPoint" "$json_path")
    device_part=$(get_device_part "$device" "$part_num")
    if [ "$mountPoint" == "/boot" ];then
      mkdir -pv $target/boot
      mount "$device_part" $target/boot
      creat_fstab "$device_part" "$mountPoint"
    fi
  done
}


mount_other_part(){
  json_path=$JSON_PATH
  device=$DEVICE
  for ((i=0;i<11;i++))
  do
    part_num=$(( i + 1 ))
    filesystem=$(jq -r ".[""$i""].filesystem" "$json_path")
    mountPoint=$(jq -r ".[""$i""].mountPoint" "$json_path")
    
    if [ "$filesystem" = "null" ];then
      break
    fi

    device_part=$(get_device_part "$device" $part_num)
    if [ "$mountPoint" != "/" ] && [ "$mountPoint" != "/boot" ] && [ "$mountPoint" != "" ] && [ "$mountPoint" != "swap" ];then
      do_mount "$mountPoint" "$device_part"
      creat_fstab "$device_part" "$mountPoint"
    fi
  done
}



do_mount(){
  mount_dir="/target/$1"
  device_part=$2

  if [ "$1" != "/data" ];then

    if [ -d "${mount_dir}" ];then
      echo "$mount_dir is already exist"
      mount "$device_part" "$mount_dir"
    else
      mkdir -pv "$mount_dir"
      mount "$device_part" "$mount_dir"
    fi
  else
      mkdir -pv "$mount_dir"
      mount "$device_part" "$mount_dir"


      mkdir -p /target/data/home
      mkdir -p /target/home
      mount --bind /target/data/home /target/home || error "Faild to mount /target/home"

      mkdir -p /target/data/opt
      mkdir -p /target/opt
      mount --bind /target/data/opt /target/opt || error "Faild to mount /target/opt"

      mkdir -p /target/root
      mkdir -p /target/data/root
      mount --bind /target/data/root /target/root || error "Faild to mount /target/root"

      mkdir -p /target/var
      mkdir -p /target/data/var
      mount --bind /target/data/var /target/var || error "Failed to mount /target/var"
  fi
}



#检查参数
check_opts(){
  if [ $# -ge 1 ];then
    echo "$@"
  else
    echo "need options!!!"
    exit 1
  fi
}



write_fstab_title(){
  sed -i '1 i # <file system> <mount point>   <type>  <options>       <dump>  <pass>'  /tmp/fstab.in
}

creat_fstab(){
  device_part=$1
  mount_dir=$2
  part_uuid=$(lsblk -o UUID "$device_part"|sed -n '$p')
  part_fstype=$(lsblk -o FSTYPE "$device_part"|sed -n '$p')
  
  if [ "$mount_dir" == "/" ];then
    echo "UUID=${part_uuid}  ${mount_dir}     ${part_fstype}    rw,relatime 0   1" >> /tmp/fstab.in
  

  elif [ "$part_fstype" == "swap" ];then
    echo "UUID=${part_uuid}   none        swap     defaults,pri=-2 0 0" >> /tmp/fstab.in
  
  
  elif [ "$mount_dir" == "/boot" ];then
    echo "UUID=${part_uuid}  ${mount_dir}     ${part_fstype}    rw,relatime 0   2" >> /tmp/fstab.in
  

  elif [ "$mount_dir" == "/boot/efi" ];then
    echo "UUID=${part_uuid}  ${mount_dir}     ${part_fstype}    rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro   0 2" >> /tmp/fstab.in
  
  elif  [ "$mount_dir" == "/data" ];then
    echo "UUID=${part_uuid}  ${mount_dir}     ${part_fstype}    rw,relatime 0   2" >> /tmp/fstab.in
    declare -g fstab_data_flag=true
  else
     echo "UUID=${part_uuid}  ${mount_dir}     ${part_fstype}    rw,relatime 0   2" >> /tmp/fstab.in

  fi

}

write_bind_data(){
  if [ "$fstab_data_flag" == "true" ];then
    echo "
/data/home /home none defaults,bind 0 0
/data/opt /opt none defaults,bind 0 0
/data/root /root none defaults,bind 0 0
/data/var /var none defaults,bind 0 0" >> /tmp/fstab.in
  fi
}

# 防止重复写入
clean_fstab(){
  if [ -f /tmp/fstab.in ];then
    rm -rf /tmp/fstab.in
  fi
}

main(){
# 扫根，挂根
# 扫boot, 挂boot
# 扫其他，挂其他
  clean_fstab
  check_opts "$@"
  DEVICE=$1
  declare -g JSON_PATH="$2"
  check_efi_mode "$3"
  find_root
  find_boot
  mount_other_part
# 写fstab预处理文件
  write_bind_data
  write_fstab_title

}

main "$@"
