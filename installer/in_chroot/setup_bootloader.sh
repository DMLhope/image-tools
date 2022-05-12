#!/bin/bash

EFI=false
DEVICE=""

#检查参数
check_opts(){
  if [ $# -ge 1 ] && [ -b "$1" ];then
    echo "$@"
  else
    echo "need device!!!"
    exit 1
  fi
}

check_dep(){
  if [ -f "$(which grub-install)" ] && [ -f "$(which update-grub)" ];then
    echo "depends check pass..."
  else
    echo "depends check error!!!!"
    exit 2
  fi

}

# Check boot mode is UEFI or not.
check_efi_mode(){
    [ -d "/sys/firmware/efi" ] && declare -g EFI=true
    # 允许接收一个参数来强制指定使用efi
    [ ! -z "$1" ] && declare -g EFI=$1
}

install_grub(){
    grub-install "$DEVICE"
    if [ "$EFI" == "true" ];then
        grub-install --target=x86_64-efi --efi-directory=/boot/efi  --bootloader-id="deepin" --recheck
    else
        grub-install --no-floppy "$DEVICE" --target=i386-pc --force 
    fi

    update-grub
}

main(){
    check_opts "$@"
    DEVICE=$1
    check_efi_mode "$2"

    install_grub

}

main "$@"