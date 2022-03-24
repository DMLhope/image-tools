#!/usr/bin/env bash

add_repo(){
  echo "deb [trusted=yes]  http://10.2.10.31/repo/project/pms947-htwy/ eagle main" >> /etc/apt/sources.list
  apt update
}
install_pkg(){
  apt install -y grub-common initramfs-tools-core openssl pciutils vim live-tools parted  gcc g++ sudo isc-dhcp-client
  apt install -y linux-headers-3.10.0-mips64-core-947=3.10.0-1005 linux-image-3.10.0-mips64-core-947=3.10.0-1005 \
          default-jdk openssh-server live-boot live-boot-initramfs-tools \
          openssh-client sqlite vsftpd ftp mariadb-common  mariadb-server mariadb-client ifenslave 
}
update_fstab(){
echo "# UNCONFIGURED FSTAB FOR BASE SYSTEM
/dev/sda1 / ext3 rw,relatime 0 1" > /etc/fstab
}
copy_grubconf(){
  if [ -f /hooks-data/11_linux ];then
          cp -v /hooks-data/11_linux /etc/grub.d/
  fi
}
copy_bootcfg(){
  if [ -f /hooks-data/boot.cfg ];then
          cp -v /hooks-data/boot.cfg /boot/
  fi
}
copy_update_grub(){
  if [ -f /hooks-data/update-grub ];then
          cp -v /hooks-data/update-grub /usr/sbin/
  fi
}

change_root_passwd(){
  echo root:a |chpasswd
}
add_user(){
  useradd -m -G sudo -s  /bin/bash -p "$(openssl passwd -1 123)" deepin
}


main(){
  add_repo
  install_pkg
  update_fstab
  copy_grubconf
  copy_bootcfg
  change_root_passwd
  add_user
}

main
