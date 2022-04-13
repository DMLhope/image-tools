#!/usr/bin/env bash

add_repo(){
  echo "deb [trusted=yes]  http://10.2.10.31/repo/project/pms806-719s-2k1000/ fou main" >> /etc/apt/sources.list
  apt update
}

apt_install() {
  DEBIAN_FRONTEND="noninteractive" apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  --allow-unauthenticated install "$@"
}

install_pkg(){
  apt install -y grub-common initramfs-tools-core live-boot \
      live-boot-initramfs-tools openssl pciutils vim live-tools parted gcc g++ sudo
  if [ -f /package.list/extra_deb.list ] && [ -f /package.list/kernel.list ] ;then
    kernel_deb=$(xargs --arg-file=/package.list/kernel.list)
    extra_deb=$(xargs --arg-file=/package.list/extra_deb.list)
    apt_install "$kernel_deb" "$extra_deb"
  else
    echo "no packagelist will install"
  fi
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
# copy_update_grub(){
#   if [ -f /hooks-data/update-grub ];then
#           cp -v /hooks-data/update-grub /usr/sbin/
#   fi
# }

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
  # copy_grubconf
  copy_bootcfg
  change_root_passwd
  add_user
}

main
