#!/bin/bash
# Mount root partition to /target.

set -x

declare JSON_PATH="./test.json"
declare DEVICE
declare target="/target"
mkdir -pv ${target}
chown -v root:root ${target}
chmod -v 0755 ${target}



get_device_part(){
  device=$1
  part_num=$2
  if [[ "$device" =~ "nvme" ]];then
      device_part=${device}p${part_num}
      echo $device_part
  else
      device_part=${device}${part_num}
      echo $device_part
  fi
}

find_root(){
  json_path=$JSON_PATH
  device=$DEVICE
  for ((i=1;i<11;i++))
  do
    mountPoint=$(jq -r ".["$i"].mountPoint" "$json_path")
    device_part=$(get_device_part $device $i)
    if [ $mountPoint == "/" ];then
      mount $device_part $target
    fi
  done
}

find_boot(){
  json_path=$JSON_PATH
  device=$DEVICE
  
  for ((i=1;i<11;i++))
  do
    local mountPoint=$(jq -r ".["$i"].mountPoint" "$json_path")
    device_part=$(get_device_part "$device" $i)
    if [ "$mountPoint" == "/boot" ];then
      mkdir -pv $target/boot
      mount "$device_part" $target/boot
    fi
  done
}


mount_other_part(){
  json_path=$JSON_PATH
  for ((i=1;i<11;i++))
  do
    filesystem=$(jq -r ".["$i"].filesystem" "$json_path")
    label=$(jq -r ".["$i"].label" "$json_path")
    mountPoint=$(jq -r ".["$i"].mountPoint" "$json_path")
    
    if [ "$filesystem" = "null" ];then
      break
    fi

    device_part=$(get_device_part "$device" $i)
    if [ "$mountPoint" != "/" ] && [ "$mountPoint" != "/boot" ] && [ "$mountPoint" != "" ];then
      do_mount "$mountPoint" "$device_part"
    fi
  done
}



do_mount(){
  mount_dir="/target/$1"
  device_part=$2

  if [ $mount_dir != "/data" ];then

    if [ -d "${mount_dir}" ];then
      echo "$mount_dir is already exist"
      mount $device_part $mount_dir
    else
      mkdir -pv $mount_dir
      mount $device_part $mount_dir
    fi
  else
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
  if [ $# -eq 1 ];then
    echo $@
  else
    echo "need options!!!"
    exit 1
  fi
}

main(){
# 扫根，挂根
# 扫boot, 挂boot
# 扫其他，挂其他
  check_opts $@
  DEVICE=$1
  find_root
  find_boot
  mount_other_part
}

main $@


