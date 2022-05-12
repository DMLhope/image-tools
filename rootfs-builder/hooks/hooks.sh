#!/usr/bin/env bash

add_repo(){
  echo "" >> /etc/apt/sources.list
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
    # 这里打死不能写成apt_install ”$kernel_deb“ ”$extra_deb“ 会被转义成带单引号的变量从而无法安装
    apt_install $kernel_deb $extra_deb
  else
    echo "no packagelist will install"
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
  change_root_passwd
  add_user
}

main
