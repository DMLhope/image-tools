#!/usr/bin/env bash

add_repo(){
  echo "" >> /etc/apt/sources.list
  apt update
}

# set_hosts(){
#   echo "192.168.1.85  mirror.feixian.software" >> /etc/hosts
# }

# clean_hosts(){
#   sed -i '/192.168.1.85/d' /etc/hosts

# }

apt_install() {
  DEBIAN_FRONTEND="noninteractive" apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  --allow-unauthenticated install "$@"
}

install_pkg(){
  apt_install  bash-completion openssl sudo vim locales-all locales openssh-server pciutils 
  if [ -f /package.list/extra_deb.list ];then
    extra_deb=$(xargs --arg-file=/package.list/extra_deb.list)
    # 这里打死不能写成apt_install ”$kernel_deb“ ”$extra_deb“ 会被转义成带单引号的变量从而无法安装
    apt_install $extra_deb
  else
    echo "no packagelist will install"
  fi
}



change_root_passwd(){
  echo root:123 |chpasswd
}

add_user(){
  useradd -m -G sudo -s  /bin/bash -p "$(openssl passwd -1 123)" fxos
}

set_hostname(){
  echo "fxos-pc" > /etc/hostname
}

main(){
  add_repo
  # set_hosts
  install_pkg
  change_root_passwd
  add_user
  set_hostname
  # clean_hosts
}

main
